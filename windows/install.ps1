[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Link', 'Copy')]
    [string]$SyncMode = 'Auto',
    [switch]$DryRun,
    [switch]$SkipPackages,
    [switch]$SkipConfigs,
    [switch]$SkipShellProfiles
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:BootstrapRoot = Split-Path -Parent $PSScriptRoot
$script:SourceRoot = Join-Path $script:BootstrapRoot 'shared'
$script:InstallRoot = Join-Path $HOME '.config\terminal-bootstrap'
$script:Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:PackageSpecs = (Import-PowerShellDataFile (Join-Path $PSScriptRoot 'packages.psd1')).Packages
$script:IsAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
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

function Resolve-SourceItemPath {
    param([string]$Source)

    $sourcePath = Get-CanonicalPath $Source
    if (Test-Path -LiteralPath $sourcePath) {
        return $sourcePath
    }

    if (-not $DryRun) {
        throw "Managed source does not exist: $sourcePath"
    }

    $installRootPath = (Get-CanonicalPath $script:InstallRoot).TrimEnd('\')
    if ($sourcePath.StartsWith($installRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $sourcePath.Substring($installRootPath.Length).TrimStart('\')
        $fallback = Join-Path $script:SourceRoot $relative
        if (Test-Path -LiteralPath $fallback) {
            return (Get-CanonicalPath $fallback)
        }
    }

    throw "Managed source does not exist: $sourcePath"
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
    Ensure-Directory (Split-Path -Parent $Target)

    if (Test-ManagedTarget -Target $Target -ExpectedSource $sourcePath) {
        Write-Host "skip  $Target already points to managed source"
        return
    }

    if (Test-Path -LiteralPath $Target) {
        Backup-Target $Target
    }

    $sourceItemPath = Resolve-SourceItemPath $sourcePath
    $sourceItem = Get-Item -LiteralPath $sourceItemPath -Force
    $effectiveMode = if ($SyncMode -eq 'Auto') { 'Link' } else { $SyncMode }

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

function Ensure-ManagedBlock {
    param(
        [string]$Path,
        [string]$BeginMarker,
        [string]$EndMarker,
        [string]$Block
    )

    $existing = if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw } else { '' }
    $pattern = '(?s)' + [regex]::Escape($BeginMarker) + '.*?' + [regex]::Escape($EndMarker)
    $managed = "$BeginMarker`r`n$Block`r`n$EndMarker"

    if ($existing -match $pattern) {
        $updated = [regex]::Replace($existing, $pattern, $managed)
    } elseif ([string]::IsNullOrWhiteSpace($existing)) {
        $updated = $managed + "`r`n"
    } else {
        $updated = $existing.TrimEnd() + "`r`n`r`n" + $managed + "`r`n"
    }

    Ensure-Directory (Split-Path -Parent $Path)
    Invoke-Action "Write managed block in $Path" {
        Set-Content -LiteralPath $Path -Value $updated
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
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machinePath, $userPath -join ';')
}

function Get-Msys2BashPath {
    $path = Resolve-EnvironmentPath '%SystemDrive%\msys64\usr\bin\bash.exe'
    if (Test-Path -LiteralPath $path) {
        return $path
    }
    return $null
}

function Test-Msys2PackageInstalled {
    param([string]$Package)

    $bash = Get-Msys2BashPath
    if (-not $bash) {
        return $false
    }

    & $bash -lc "pacman -Qi $Package >/dev/null 2>&1"
    return $LASTEXITCODE -eq 0
}

function Install-Msys2Package {
    param([string]$Package)

    if (Test-Msys2PackageInstalled $Package) {
        Write-Host "skip  MSYS2 package already installed: $Package"
        return
    }

    $bash = Get-Msys2BashPath
    if (-not $bash) {
        if ($DryRun) {
            Write-Host "[dry-run] Install MSYS2 package $Package" -ForegroundColor Yellow
            return
        }
        throw "MSYS2 bash not found. Cannot install MSYS2 package: $Package"
    }

    Invoke-Action "Install MSYS2 package $Package" {
        & $bash -lc "pacman -S --needed --noconfirm $Package"
        if ($LASTEXITCODE -ne 0) {
            throw "pacman install failed for $Package"
        }
    }
}

function Install-Package {
    param($Spec)

    if (Test-PackageInstalled $Spec) {
        Write-Host "skip  package already installed: $($Spec.Name)"
        return
    }

    if ($Spec.ContainsKey('WingetId') -and $Spec.WingetId -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Invoke-Action "Install $($Spec.Name) via winget ($($Spec.WingetId))" {
            & winget install --exact --id $Spec.WingetId --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
            if ($LASTEXITCODE -ne 0) {
                throw "winget install failed for $($Spec.Name)"
            }
        }
        Refresh-SessionPath
        return
    }

    if ($Spec.ContainsKey('RequiresAdmin') -and $Spec.RequiresAdmin -and -not $script:IsAdministrator) {
        $message = "skip  package requires administrator rights in this environment: $($Spec.Name)"
        if ($Spec.ContainsKey('Optional') -and $Spec.Optional) {
            Write-Warning $message
            return
        }
        throw $message
    }

    if ($Spec.ContainsKey('Chocolatey') -and $Spec.Chocolatey -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        try {
            Invoke-Action "Install $($Spec.Name) via choco ($($Spec.Chocolatey))" {
                & choco install $Spec.Chocolatey -y --no-progress
                if ($LASTEXITCODE -ne 0) {
                    throw "choco install failed for $($Spec.Name)"
                }
            }
            Refresh-SessionPath
            return
        } catch {
            if ($Spec.ContainsKey('Optional') -and $Spec.Optional) {
                Write-Warning "Optional package install failed: $($Spec.Name). $_"
                return
            }
            throw
        }
    }

    throw "No installer available for $($Spec.Name)"
}

function Install-Packages {
    Write-Section 'Packages'
    foreach ($spec in $script:PackageSpecs) {
        Install-Package $spec
    }

    Install-Msys2Package 'tmux'
}

function Sync-StagedAssets {
    Write-Section 'Stage Managed Assets'

    $mappings = @(
        @{ Source = Join-Path $script:SourceRoot 'fonts'; Target = Join-Path $script:InstallRoot 'fonts' },
        @{ Source = Join-Path $script:SourceRoot 'shell'; Target = Join-Path $script:InstallRoot 'shell' },
        @{ Source = Join-Path $script:SourceRoot 'starship'; Target = Join-Path $script:InstallRoot 'starship' },
        @{ Source = Join-Path $script:SourceRoot 'tmux'; Target = Join-Path $script:InstallRoot 'tmux' },
        @{ Source = Join-Path $script:SourceRoot 'wezterm'; Target = Join-Path $script:InstallRoot 'wezterm' },
        @{ Source = Join-Path $script:SourceRoot 'nvim'; Target = Join-Path $script:InstallRoot 'nvim' }
    )

    foreach ($mapping in $mappings) {
        Sync-Target -Source $mapping.Source -Target $mapping.Target
    }
}

function Sync-AppConfigs {
    Write-Section 'Application Config Targets'

    $weztermConfigRoot = Join-Path $HOME '.config\wezterm'
    Ensure-Directory $weztermConfigRoot

    Sync-Target -Source (Join-Path $script:InstallRoot 'wezterm\wezterm.lua') -Target (Join-Path $HOME '.wezterm.lua')
    Sync-Target -Source (Join-Path $script:InstallRoot 'wezterm\wezterm-shell-integration.sh') -Target (Join-Path $weztermConfigRoot 'wezterm-shell-integration.sh')
    Sync-Target -Source (Join-Path $script:InstallRoot 'starship\starship.toml') -Target (Join-Path $HOME '.config\starship.toml')
    Sync-Target -Source (Join-Path $script:InstallRoot 'tmux\.tmux.conf') -Target (Join-Path $HOME '.tmux.conf')
    Sync-Target -Source (Join-Path $script:InstallRoot 'nvim') -Target (Join-Path $env:LOCALAPPDATA 'nvim')
}

function Update-ShellProfiles {
    Write-Section 'Shell Profiles'

    $bashAliasesBlock = @'
if [ -f "$HOME/.config/terminal-bootstrap/shell/aliases.sh" ]; then
  . "$HOME/.config/terminal-bootstrap/shell/aliases.sh"
fi
'@

    $bashProfileBlock = @'
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
'@

    Ensure-ManagedBlock -Path (Join-Path $HOME '.bashrc') `
        -BeginMarker '# >>> terminal-bootstrap >>>' `
        -EndMarker '# <<< terminal-bootstrap <<<' `
        -Block $bashAliasesBlock

    Ensure-ManagedBlock -Path (Join-Path $HOME '.bash_profile') `
        -BeginMarker '# >>> terminal-bootstrap-bash-profile >>>' `
        -EndMarker '# <<< terminal-bootstrap-bash-profile <<<' `
        -Block $bashProfileBlock

    $pwshProfilePath = $PROFILE.CurrentUserCurrentHost
    $pwshBlock = @'
$terminalBootstrapShell = Join-Path $HOME '.config\terminal-bootstrap\shell\aliases.ps1'
if (Test-Path $terminalBootstrapShell) {
    . $terminalBootstrapShell
}
'@

    Ensure-ManagedBlock -Path $pwshProfilePath `
        -BeginMarker '# >>> terminal-bootstrap >>>' `
        -EndMarker '# <<< terminal-bootstrap <<<' `
        -Block $pwshBlock
}

Write-Host "terminal-bootstrap Windows installer"
Write-Host "Mode: $SyncMode"
Write-Host "DryRun: $DryRun"

if (-not $SkipPackages) {
    Install-Packages
}

if (-not $SkipConfigs) {
    Sync-StagedAssets
    Sync-AppConfigs
}

if (-not $SkipShellProfiles) {
    Update-ShellProfiles
}

Write-Host ""
Write-Host "Windows bootstrap plan complete."
if ($DryRun) {
    Write-Host "Dry run only. No package or file changes were applied."
}
