Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalSystemDrive = $env:SystemDrive
$originalXdgConfigHome = $env:XDG_CONFIG_HOME
$originalLocalAppData = $env:LOCALAPPDATA
$originalAquaRootDir = $env:AQUA_ROOT_DIR

try {
    $configRoot = Join-Path $testRoot 'config'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $localAppData = Join-Path $testRoot 'LocalAppData'
    $emptyConfig = Join-Path $testRoot 'config.nu'
    $expectedAquaRoot = Join-Path $testRoot '.aqua'

    New-Item -ItemType Directory -Force -Path $nushellConfigRoot,(Join-Path $expectedAquaRoot 'bin') | Out-Null
    Set-Content -LiteralPath $emptyConfig -Value ''
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'config.nu') -Value ''

    $env:SystemDrive = $testRoot
    $env:XDG_CONFIG_HOME = $configRoot
    $env:LOCALAPPDATA = $localAppData
    $env:NU_TEST_EXPECTED_AQUA_ROOT_DIR = $expectedAquaRoot
    Remove-Item Env:\AQUA_ROOT_DIR -ErrorAction SilentlyContinue

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\windows-aqua-root-dir.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "windows aqua root env test failed with exit code $LASTEXITCODE"
    }

    $customAquaRoot = Join-Path $testRoot 'custom-aqua'
    New-Item -ItemType Directory -Force -Path (Join-Path $customAquaRoot 'bin') | Out-Null
    $env:AQUA_ROOT_DIR = $customAquaRoot
    $env:NU_TEST_EXPECTED_AQUA_ROOT_DIR = $customAquaRoot

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\windows-aqua-root-dir.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "windows aqua root preservation test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_AQUA_ROOT_DIR -ErrorAction SilentlyContinue
    if ($null -eq $originalSystemDrive) {
        Remove-Item Env:\SystemDrive -ErrorAction SilentlyContinue
    } else {
        $env:SystemDrive = $originalSystemDrive
    }
    if ($null -eq $originalXdgConfigHome) {
        Remove-Item Env:\XDG_CONFIG_HOME -ErrorAction SilentlyContinue
    } else {
        $env:XDG_CONFIG_HOME = $originalXdgConfigHome
    }
    if ($null -eq $originalLocalAppData) {
        Remove-Item Env:\LOCALAPPDATA -ErrorAction SilentlyContinue
    } else {
        $env:LOCALAPPDATA = $originalLocalAppData
    }
    if ($null -eq $originalAquaRootDir) {
        Remove-Item Env:\AQUA_ROOT_DIR -ErrorAction SilentlyContinue
    } else {
        $env:AQUA_ROOT_DIR = $originalAquaRootDir
    }
}
