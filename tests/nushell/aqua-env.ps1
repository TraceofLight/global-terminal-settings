Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalSystemDrive = $env:SystemDrive
$originalXdgConfigHome = $env:XDG_CONFIG_HOME
$originalLocalAppData = $env:LOCALAPPDATA
$originalAquaGlobalConfig = $env:AQUA_GLOBAL_CONFIG
$originalAquaRootDir = $env:AQUA_ROOT_DIR

try {
    $configRoot = Join-Path $testRoot 'config'
    $aquaConfigRoot = Join-Path $configRoot 'aquaproj-aqua'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $localAppData = Join-Path $testRoot 'LocalAppData'
    $aquaRoot = Join-Path $testRoot '.aqua'
    $aquaBin = Join-Path $aquaRoot 'bin'
    $aquaExeDir = Join-Path $localAppData 'Microsoft\WinGet\Packages\aquaproj.aqua_Microsoft.Winget.Source_8wekyb3d8bbwe'
    $aquaConfig = Join-Path $aquaConfigRoot 'aqua.yaml'
    $customAquaConfig = Join-Path $aquaConfigRoot 'user-aqua.yaml'
    $emptyConfig = Join-Path $testRoot 'config.nu'

    New-Item -ItemType Directory -Force -Path $aquaConfigRoot, $nushellConfigRoot, $aquaBin, $aquaExeDir | Out-Null
    Set-Content -LiteralPath $aquaConfig -Value 'registries: []'
    Set-Content -LiteralPath $customAquaConfig -Value 'registries: []'
    Set-Content -LiteralPath $emptyConfig -Value ''
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'config.nu') -Value ''

    $env:NU_TEST_EXPECTED_CONFIG = $aquaConfig
    $env:NU_TEST_EXPECTED_AQUA_BIN = $aquaBin
    $env:NU_TEST_EXPECTED_AQUA_EXE_DIR = $aquaExeDir
    $env:SystemDrive = $testRoot
    $env:XDG_CONFIG_HOME = $configRoot
    $env:LOCALAPPDATA = $localAppData
    Remove-Item Env:\AQUA_GLOBAL_CONFIG -ErrorAction SilentlyContinue
    Remove-Item Env:\AQUA_ROOT_DIR -ErrorAction SilentlyContinue

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\aqua-env.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "aqua env test failed with exit code $LASTEXITCODE"
    }

    $env:AQUA_GLOBAL_CONFIG = $customAquaConfig
    $env:NU_TEST_EXPECTED_CONFIG = $customAquaConfig
    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\aqua-env.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "aqua env custom config preservation test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_CONFIG -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_AQUA_BIN -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_AQUA_EXE_DIR -ErrorAction SilentlyContinue
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
    if ($null -eq $originalAquaGlobalConfig) {
        Remove-Item Env:\AQUA_GLOBAL_CONFIG -ErrorAction SilentlyContinue
    } else {
        $env:AQUA_GLOBAL_CONFIG = $originalAquaGlobalConfig
    }
    if ($null -eq $originalAquaRootDir) {
        Remove-Item Env:\AQUA_ROOT_DIR -ErrorAction SilentlyContinue
    } else {
        $env:AQUA_ROOT_DIR = $originalAquaRootDir
    }
}
