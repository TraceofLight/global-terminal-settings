Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Invoke-RepoCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    $output = & $FilePath @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $FilePath $($Arguments -join ' ')`n$output"
    }

    return ($output -join "`n")
}

Push-Location $repoRoot
try {
    $windowsOutput = Invoke-RepoCommand -FilePath 'pwsh' -Arguments @(
        '-NoProfile',
        '-File',
        '.\windows\install.ps1',
        '-DryRun',
        '-SkipPackages'
    )

    $macOutput = Invoke-RepoCommand -FilePath 'bash' -Arguments @(
        './mac/install.sh',
        '--dry-run',
        '--skip-packages'
    )

    $linuxOutput = Invoke-RepoCommand -FilePath 'bash' -Arguments @(
        './linux/install.sh',
        '--dry-run',
        '--skip-packages',
        '--target',
        'linux'
    )
} finally {
    Pop-Location
}

$combinedOutput = @($windowsOutput, $macOutput, $linuxOutput) -join "`n"

foreach ($pattern in @('aqua', 'aqua.yaml', 'Aqua')) {
    if ($combinedOutput -notmatch [regex]::Escape($pattern)) {
        throw "Expected installer dry-runs to mention '$pattern'."
    }
}
