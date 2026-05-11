Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalXdgConfigHome = $env:XDG_CONFIG_HOME
$originalLocalAppData = $env:LOCALAPPDATA

try {
    $configRoot = Join-Path $testRoot 'config'
    $aquaConfigRoot = Join-Path $configRoot 'aquaproj-aqua'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $localAppData = Join-Path $testRoot 'LocalAppData'
    $aquaBin = Join-Path $localAppData 'aquaproj-aqua\bin'
    $aquaExeDir = Join-Path $localAppData 'Microsoft\WinGet\Packages\aquaproj.aqua_Microsoft.Winget.Source_8wekyb3d8bbwe'
    $aquaConfig = Join-Path $aquaConfigRoot 'aqua.yaml'
    $emptyConfig = Join-Path $testRoot 'config.nu'

    New-Item -ItemType Directory -Force -Path $aquaConfigRoot, $nushellConfigRoot, $aquaBin, $aquaExeDir | Out-Null
    Set-Content -LiteralPath $aquaConfig -Value 'registries: []'
    Set-Content -LiteralPath $emptyConfig -Value ''
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'config.nu') -Value ''

    $env:NU_TEST_EXPECTED_CONFIG = $aquaConfig
    $env:NU_TEST_EXPECTED_AQUA_BIN = $aquaBin
    $env:NU_TEST_EXPECTED_AQUA_EXE_DIR = $aquaExeDir
    $env:XDG_CONFIG_HOME = $configRoot
    $env:LOCALAPPDATA = $localAppData

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\aqua-env.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "aqua env test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_CONFIG -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_AQUA_BIN -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_AQUA_EXE_DIR -ErrorAction SilentlyContinue
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
}
