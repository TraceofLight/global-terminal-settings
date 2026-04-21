[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Link', 'Copy')]
    [string]$SyncMode = 'Copy',
    [switch]$DryRun,
    [switch]$SkipPackages,
    [switch]$SkipConfigs
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'packages.psd1')
$script:BootstrapRoot = Split-Path -Parent $PSScriptRoot
$script:SourceRoot = Join-Path $script:BootstrapRoot 'shared'
$script:InstallRoot = Join-Path $HOME '.config\terminal-bootstrap'
$script:Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:PackageSpecs = $manifest.Packages
$script:CanonicalNushellConfigRoot = Join-Path $HOME '.config\nushell'
$script:LegacyNushellConfigRoot = Join-Path $env:APPDATA 'nushell'
$script:DefaultNushellExecutable = Join-Path $env:LOCALAPPDATA 'Programs\nu\bin\nu.exe'

function Write-Stage {
    param(
        [int]$Number,
        [string]$Title
    )

    Write-Host ""
    Write-Host "== $Number. $Title ==" -ForegroundColor Cyan
}

function Invoke-Action {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Host "[dry-run] $Description" -ForegroundColor Yellow
        return
    }

    Write-Host ">> $Description"
    & $Action
}

function Get-CanonicalPath {
    param([string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-EnvironmentPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    return [System.Environment]::ExpandEnvironmentVariables($Path)
}

function Ensure-Directory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return
    }

    Invoke-Action "Create directory $Path" {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Resolve-LinkTarget {
    param([string]$Target)

    if (-not (Test-Path -LiteralPath $Target)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Target -Force
    if (-not $item.Target) {
        return $null
    }

    $resolved = $item.Target
    if ($resolved -is [array]) {
        $resolved = $resolved[0]
    }
    if (-not [System.IO.Path]::IsPathRooted($resolved)) {
        $resolved = Join-Path (Split-Path -Parent $Target) $resolved
    }

    return (Get-CanonicalPath $resolved)
}

function Test-ManagedTarget {
    param(
        [string]$Target,
        [string]$ExpectedSource
    )

    if (-not (Test-Path -LiteralPath $Target)) {
        return $false
    }

    $resolved = Resolve-LinkTarget $Target
    if (-not $resolved) {
        return $false
    }

    return $resolved -eq (Get-CanonicalPath $ExpectedSource)
}

function Backup-Target {
    param([string]$Target)

    if (-not (Test-Path -LiteralPath $Target)) {
        return
    }

    $backup = "$Target.pre-terminal-bootstrap-$($script:Timestamp)"
    Invoke-Action "Backup $Target to $backup" {
        Move-Item -LiteralPath $Target -Destination $backup
    }
}

function Sync-Target {
    param(
        [string]$Source,
        [string]$Target
    )

    $sourcePath = Get-CanonicalPath $Source
    if (-not (Test-Path -LiteralPath $sourcePath) -and $DryRun) {
        $installRootPath = (Get-CanonicalPath $script:InstallRoot).TrimEnd('\')
        if ($sourcePath.StartsWith($installRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $sourcePath.Substring($installRootPath.Length).TrimStart('\')
            $fallback = Join-Path $script:SourceRoot $relative
            if (Test-Path -LiteralPath $fallback) {
                $sourcePath = Get-CanonicalPath $fallback
            }
        }
    }
    Ensure-Directory (Split-Path -Parent $Target)

    $sourceItem = Get-Item -LiteralPath $sourcePath -Force
    $effectiveMode = if ($SyncMode -eq 'Auto') { 'Link' } else { $SyncMode }

    if ($effectiveMode -ne 'Copy' -and (Test-ManagedTarget -Target $Target -ExpectedSource $sourcePath)) {
        Write-Host "skip  $Target already points to managed source"
        return
    }

    if (Test-Path -LiteralPath $Target) {
        Backup-Target $Target
    }

    if ($effectiveMode -eq 'Link') {
        $linkType = if ($sourceItem.PSIsContainer) { 'Junction' } else { 'SymbolicLink' }
        try {
            Invoke-Action "Link $Target -> $sourcePath" {
                New-Item -ItemType $linkType -Path $Target -Target $sourcePath | Out-Null
            }
            return
        } catch {
            if ($SyncMode -ne 'Auto') {
                throw
            }
            Write-Warning "Link failed for $Target. Falling back to copy. $_"
        }
    }

    if ($sourceItem.PSIsContainer) {
        Invoke-Action "Copy directory $sourcePath -> $Target" {
            Copy-Item -LiteralPath $sourcePath -Destination $Target -Recurse -Force
        }
    } else {
        Invoke-Action "Copy file $sourcePath -> $Target" {
            Copy-Item -LiteralPath $sourcePath -Destination $Target -Force
        }
    }
}

function Copy-ManagedFile {
    param(
        [string]$Source,
        [string]$Target
    )

    $sourcePath = Get-CanonicalPath $Source
    Ensure-Directory (Split-Path -Parent $Target)

    if (Test-Path -LiteralPath $Target) {
        $item = Get-Item -LiteralPath $Target -Force
        if ($item.Target -or $item.LinkType) {
            Backup-Target $Target
        } elseif (-not $item.PSIsContainer) {
            $sourceHash = (Get-FileHash -LiteralPath $sourcePath).Hash
            $targetHash = (Get-FileHash -LiteralPath $Target).Hash
            if ($sourceHash -eq $targetHash) {
                Write-Host "skip  $Target already matches managed source"
                return
            }
            Backup-Target $Target
        } else {
            Backup-Target $Target
        }
    }

    Invoke-Action "Copy managed file $sourcePath -> $Target" {
        Copy-Item -LiteralPath $sourcePath -Destination $Target -Force
    }
}

function Remove-LegacyNuAutoloadArtifacts {
    param([string]$AutoloadRoot)

    $legacyFiles = @(
        'openclaude-completions.nu'
    )

    foreach ($legacyFile in $legacyFiles) {
        $legacyTarget = Join-Path $AutoloadRoot $legacyFile
        if (-not (Test-Path -LiteralPath $legacyTarget)) {
            continue
        }

        Backup-Target $legacyTarget
    }
}

function Test-PackageInstalled {
    param($Spec)

    if ($Spec.ContainsKey('DetectPath') -and $Spec.DetectPath) {
        $detectPath = Resolve-EnvironmentPath $Spec.DetectPath
        if (Test-Path -LiteralPath $detectPath) {
            return $true
        }
    }

    if ($Spec.ContainsKey('DetectCommand') -and $Spec.DetectCommand) {
        if (Get-Command $Spec.DetectCommand -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    return $false
}

function Refresh-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machinePath, $userPath) -join ';'
}

function Set-UserEnvironmentDefaults {
    $desiredXdgConfigHome = Join-Path $HOME '.config'
    $currentXdgConfigHome = [Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME', 'User')
    if ($currentXdgConfigHome -ne $desiredXdgConfigHome) {
        Invoke-Action "Set user XDG_CONFIG_HOME to $desiredXdgConfigHome" {
            [Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $desiredXdgConfigHome, 'User')
        }
    }

    $pathEntriesToAdd = @(
        (Join-Path $env:APPDATA 'npm')
        (Join-Path $HOME '.local\bin')
    ) | Where-Object { Test-Path -LiteralPath $_ }

    if ($pathEntriesToAdd.Count -gt 0) {
        $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $userPathEntries = @($currentUserPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $updatedUserPathEntries = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $pathEntriesToAdd) {
            $alreadyPresent = $false
            foreach ($existingEntry in $userPathEntries) {
                if ((Get-CanonicalPath $existingEntry) -eq (Get-CanonicalPath $entry)) {
                    $alreadyPresent = $true
                    break
                }
            }

            if (-not $alreadyPresent) {
                $updatedUserPathEntries.Add($entry)
            }
        }

        if ($updatedUserPathEntries.Count -gt 0) {
            $newUserPath = (($updatedUserPathEntries + $userPathEntries) -join ';')
            Invoke-Action "Update user PATH for terminal tooling" {
                [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
            }
            Refresh-SessionPath
        }
    }
}

function Get-NushellConfigRoot {
    return $script:CanonicalNushellConfigRoot
}

function Backup-LegacyNushellConfigRoot {
    $legacyRoot = $script:LegacyNushellConfigRoot
    $canonicalRoot = $script:CanonicalNushellConfigRoot

    if ([string]::IsNullOrWhiteSpace($legacyRoot) -or [string]::IsNullOrWhiteSpace($canonicalRoot)) {
        return
    }

    if ((Get-CanonicalPath $legacyRoot) -eq (Get-CanonicalPath $canonicalRoot)) {
        return
    }

    if (-not (Test-Path -LiteralPath $legacyRoot)) {
        return
    }

    if (Test-ManagedTarget -Target $legacyRoot -ExpectedSource $canonicalRoot) {
        return
    }

    Backup-Target $legacyRoot
}

function Ensure-NushellCompatibilityLink {
    $legacyRoot = $script:LegacyNushellConfigRoot
    $canonicalRoot = $script:CanonicalNushellConfigRoot

    if ([string]::IsNullOrWhiteSpace($legacyRoot) -or [string]::IsNullOrWhiteSpace($canonicalRoot)) {
        return
    }

    if ((Get-CanonicalPath $legacyRoot) -eq (Get-CanonicalPath $canonicalRoot)) {
        return
    }

    Ensure-Directory (Split-Path -Parent $legacyRoot)

    if (Test-ManagedTarget -Target $legacyRoot -ExpectedSource $canonicalRoot) {
        Write-Host "skip  $legacyRoot already points to managed NuShell root"
        return
    }

    if (Test-Path -LiteralPath $legacyRoot) {
        Backup-Target $legacyRoot
    }

    Invoke-Action "Link $legacyRoot -> $canonicalRoot" {
        New-Item -ItemType Junction -Path $legacyRoot -Target $canonicalRoot | Out-Null
    }
}

function Install-Package {
    param($Spec)

    if (Test-PackageInstalled $Spec) {
        Write-Host "skip  Package already installed: $($Spec.Name)"
        return
    }

    $installed = $false

    if ($Spec.ContainsKey('WingetId') -and $Spec.WingetId) {
        Invoke-Action "Install $($Spec.Name) with winget" {
            winget install --id $Spec.WingetId --exact --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
        }
        Refresh-SessionPath
        if (Test-PackageInstalled $Spec) {
            $installed = $true
        }
    }

    if (-not $installed -and $Spec.ContainsKey('Chocolatey') -and $Spec.Chocolatey) {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            if ($Spec.ContainsKey('Optional') -and $Spec.Optional) {
                Write-Warning "Chocolatey is not available. Skipping optional package: $($Spec.Name)"
                return
            }

            throw "Chocolatey is required for package $($Spec.Name) but is not available."
        }

        if (($Spec.ContainsKey('RequiresAdmin') -and $Spec.RequiresAdmin) -and -not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            if ($Spec.ContainsKey('Optional') -and $Spec.Optional) {
                Write-Warning "Administrator privileges required for optional package: $($Spec.Name). Skipping."
                return
            }

            throw "Administrator privileges required for package $($Spec.Name)."
        }

        Invoke-Action "Install $($Spec.Name) with choco" {
            choco install $Spec.Chocolatey -y --no-progress
        }
        Refresh-SessionPath
        if (Test-PackageInstalled $Spec) {
            $installed = $true
        }
    }

    if (-not $installed -and -not $DryRun) {
        throw "Failed to install package: $($Spec.Name)"
    }
}

function Install-Packages {
    Write-Stage 2 'Core Packages'

    foreach ($spec in $script:PackageSpecs) {
        Install-Package $spec
    }
}

function Stage-Assets {
    Write-Stage 3 'Stage Managed Assets'

    Sync-Target -Source (Join-Path $script:SourceRoot 'fonts') -Target (Join-Path $script:InstallRoot 'fonts')
    Sync-Target -Source (Join-Path $script:SourceRoot 'nushell') -Target (Join-Path $script:InstallRoot 'nushell')
    Sync-Target -Source (Join-Path $script:SourceRoot 'starship') -Target (Join-Path $script:InstallRoot 'starship')
    Sync-Target -Source (Join-Path $script:SourceRoot 'wezterm') -Target (Join-Path $script:InstallRoot 'wezterm')
    Sync-Target -Source (Join-Path $script:SourceRoot 'nvim') -Target (Join-Path $script:InstallRoot 'nvim')
}

function Initialize-NuAutoload {
    Write-Stage 6 'Starship, zoxide, fzf, carapace, claude, openclaude'

    $autoloadRoot = Join-Path (Get-NushellConfigRoot) 'autoload'
    Ensure-Directory $autoloadRoot

    $carapaceTarget = Join-Path $autoloadRoot 'carapace.nu'
    $starshipTarget = Join-Path $autoloadRoot 'starship.nu'
    $zoxideTarget = Join-Path $autoloadRoot 'zoxide.nu'
    $noOpScript = "# managed by terminal-bootstrap`n"

    if (Get-Command carapace -ErrorAction SilentlyContinue) {
        Invoke-Action "Generate NuShell Carapace autoload" {
            & carapace _carapace nushell | Set-Content -LiteralPath $carapaceTarget
        }
    } else {
        Write-Warning 'carapace command not found. Writing no-op NuShell Carapace autoload.'
        Invoke-Action "Write NuShell Carapace autoload placeholder" {
            Set-Content -LiteralPath $carapaceTarget -Value $noOpScript
        }
    }

    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Invoke-Action "Generate NuShell Starship autoload" {
            & starship init nu | Set-Content -LiteralPath $starshipTarget
        }
    } else {
        Write-Warning 'starship command not found. Writing no-op NuShell Starship autoload.'
        Invoke-Action "Write NuShell Starship autoload placeholder" {
            Set-Content -LiteralPath $starshipTarget -Value $noOpScript
        }
    }

    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Action "Generate NuShell zoxide autoload" {
            & zoxide init nushell | Set-Content -LiteralPath $zoxideTarget
        }
    } else {
        Write-Warning 'zoxide command not found. Writing no-op NuShell zoxide autoload.'
        Invoke-Action "Write NuShell zoxide autoload placeholder" {
            Set-Content -LiteralPath $zoxideTarget -Value $noOpScript
        }
    }

    $openClaudeTarget = Join-Path $autoloadRoot 'openclaude.nu'
    if (Get-Command openclaude -ErrorAction SilentlyContinue) {
        Invoke-Action "Write NuShell OpenClaude autoload marker" {
            Set-Content -LiteralPath $openClaudeTarget -Value "# managed by terminal-bootstrap`n# openclaude detected`n"
        }
    } else {
        Write-Warning 'openclaude command not found. Writing no-op NuShell OpenClaude autoload.'
        Invoke-Action "Write NuShell OpenClaude autoload placeholder" {
            Set-Content -LiteralPath $openClaudeTarget -Value $noOpScript
        }
    }

    $claudeTarget = Join-Path $autoloadRoot 'claude.nu'
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Invoke-Action "Write NuShell Claude autoload marker" {
            Set-Content -LiteralPath $claudeTarget -Value "# managed by terminal-bootstrap`n# claude detected`n"
        }
    } else {
        Write-Warning 'claude command not found. Writing no-op NuShell Claude autoload.'
        Invoke-Action "Write NuShell Claude autoload placeholder" {
            Set-Content -LiteralPath $claudeTarget -Value $noOpScript
        }
    }
}

function Sync-AppConfigs {
    Write-Stage 4 'Wire WezTerm'

    $configRoot = Join-Path $HOME '.config'
    $weztermConfigRoot = Join-Path $configRoot 'wezterm'
    $starshipTarget = Join-Path $configRoot 'starship.toml'
    $nvimTarget = Join-Path $env:LOCALAPPDATA 'nvim'
    $nushellConfigRoot = Get-NushellConfigRoot
    $autoloadTargetRoot = Join-Path $nushellConfigRoot 'autoload'

    Ensure-Directory $configRoot
    Ensure-Directory $weztermConfigRoot
    Backup-LegacyNushellConfigRoot
    Ensure-Directory $nushellConfigRoot
    Ensure-Directory $autoloadTargetRoot

    Sync-Target -Source (Join-Path $script:InstallRoot 'wezterm\wezterm.lua') -Target (Join-Path $HOME '.wezterm.lua')
    Sync-Target -Source (Join-Path $script:InstallRoot 'starship\starship.toml') -Target $starshipTarget

    Write-Stage 5 'Wire NuShell'
    Remove-LegacyNuAutoloadArtifacts -AutoloadRoot $autoloadTargetRoot
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\config.nu') -Target (Join-Path $nushellConfigRoot 'config.nu')
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\env.nu') -Target (Join-Path $nushellConfigRoot 'env.nu')
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\login.nu') -Target (Join-Path $nushellConfigRoot 'login.nu')
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\autoload\wezterm-integration.nu') -Target (Join-Path $autoloadTargetRoot 'wezterm-integration.nu')
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\autoload\openclaude-integration.nu') -Target (Join-Path $autoloadTargetRoot 'openclaude-integration.nu')
    Copy-ManagedFile -Source (Join-Path $script:InstallRoot 'nushell\autoload\claude-integration.nu') -Target (Join-Path $autoloadTargetRoot 'claude-integration.nu')

    $script:NvimTarget = $nvimTarget
}

function Sync-NvimConfig {
    Write-Stage 7 'Sync LazyVim'

    Sync-Target -Source (Join-Path $script:InstallRoot 'nvim') -Target $script:NvimTarget
}

Write-Host 'terminal-bootstrap windows installer'
Write-Host "Mode: $SyncMode"
Write-Host "DryRun: $DryRun"

Write-Stage 1 'Package Manager Readiness'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required for the primary Windows install path.'
}
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Warning 'Chocolatey is not available. Fallback packages will be skipped or fail if required.'
}

if (-not $SkipPackages) {
    Install-Packages
}

if (-not $SkipConfigs) {
    Set-UserEnvironmentDefaults
    Stage-Assets
    Sync-AppConfigs
    Initialize-NuAutoload
    Ensure-NushellCompatibilityLink
    Sync-NvimConfig
}

Write-Stage 8 'Verify'
if ($DryRun) {
    Write-Host 'Run `pwsh -NoProfile -File .\windows\install.ps1` to apply the baseline, then launch WezTerm to verify the NuShell entrypoint.'
} else {
    Write-Host 'Launch WezTerm to verify the NuShell entrypoint.'
}
