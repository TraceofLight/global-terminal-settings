Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalHome = $env:HOME
$originalUserProfile = $env:USERPROFILE
$originalXdgConfigHome = $env:XDG_CONFIG_HOME
$originalStarshipConfig = $env:STARSHIP_CONFIG

try {
    $testHome = Join-Path $testRoot 'home'
    $configRoot = Join-Path $testHome '.config'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $starshipConfig = Join-Path $configRoot 'starship.toml'
    $emptyConfig = Join-Path $testRoot 'config.nu'

    New-Item -ItemType Directory -Force -Path $nushellConfigRoot | Out-Null
    Set-Content -LiteralPath $starshipConfig -Value 'add_newline = false'
    Set-Content -LiteralPath $emptyConfig -Value ''
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'config.nu') -Value ''

    $env:HOME = $testHome
    $env:USERPROFILE = $testHome
    Remove-Item Env:\XDG_CONFIG_HOME -ErrorAction SilentlyContinue
    Remove-Item Env:\STARSHIP_CONFIG -ErrorAction SilentlyContinue

    $env:NU_TEST_EXPECTED_XDG_CONFIG_HOME = $configRoot
    $env:NU_TEST_EXPECTED_STARSHIP_CONFIG = $starshipConfig

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\starship-env.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "starship env test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_XDG_CONFIG_HOME -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_STARSHIP_CONFIG -ErrorAction SilentlyContinue
    if ($null -eq $originalHome) {
        Remove-Item Env:\HOME -ErrorAction SilentlyContinue
    } else {
        $env:HOME = $originalHome
    }
    if ($null -eq $originalUserProfile) {
        Remove-Item Env:\USERPROFILE -ErrorAction SilentlyContinue
    } else {
        $env:USERPROFILE = $originalUserProfile
    }
    if ($null -eq $originalXdgConfigHome) {
        Remove-Item Env:\XDG_CONFIG_HOME -ErrorAction SilentlyContinue
    } else {
        $env:XDG_CONFIG_HOME = $originalXdgConfigHome
    }
    if ($null -eq $originalStarshipConfig) {
        Remove-Item Env:\STARSHIP_CONFIG -ErrorAction SilentlyContinue
    } else {
        $env:STARSHIP_CONFIG = $originalStarshipConfig
    }
}
