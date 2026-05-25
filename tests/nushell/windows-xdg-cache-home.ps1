Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalHome = $env:HOME
$originalUserProfile = $env:USERPROFILE
$originalXdgCacheHome = $env:XDG_CACHE_HOME

try {
    $testHome = Join-Path $testRoot 'home'
    $configRoot = Join-Path $testHome '.config'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $emptyConfig = Join-Path $testRoot 'config.nu'
    $expectedCacheHome = Join-Path $testHome '.cache'

    New-Item -ItemType Directory -Force -Path $nushellConfigRoot | Out-Null
    Set-Content -LiteralPath $emptyConfig -Value ''
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'config.nu') -Value ''

    $env:HOME = $testHome
    $env:USERPROFILE = $testHome
    Remove-Item Env:\XDG_CACHE_HOME -ErrorAction SilentlyContinue

    $env:NU_TEST_EXPECTED_XDG_CACHE_HOME = $expectedCacheHome

    & nu --config $emptyConfig --env-config (Join-Path $repoRoot 'shared\nushell\env.nu') (Join-Path $repoRoot 'tests\nushell\windows-xdg-cache-home.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "windows XDG cache home env test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\NU_TEST_EXPECTED_XDG_CACHE_HOME -ErrorAction SilentlyContinue
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
    if ($null -eq $originalXdgCacheHome) {
        Remove-Item Env:\XDG_CACHE_HOME -ErrorAction SilentlyContinue
    } else {
        $env:XDG_CACHE_HOME = $originalXdgCacheHome
    }
}
