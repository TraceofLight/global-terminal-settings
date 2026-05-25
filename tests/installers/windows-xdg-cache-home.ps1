Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'windows\install.ps1'
$content = Get-Content -LiteralPath $installer -Raw

if ($content -notmatch [regex]::Escape('XDG_CACHE_HOME')) {
    throw 'Expected windows installer to manage user XDG_CACHE_HOME.'
}

if ($content -notmatch [regex]::Escape("Join-Path `$HOME '.cache'")) {
    throw 'Expected windows installer to use %USERPROFILE%\.cache as the XDG cache root.'
}

if ($content -notmatch '\[Environment\]::SetEnvironmentVariable\(''XDG_CACHE_HOME''') {
    throw 'Expected windows installer to persist XDG_CACHE_HOME in the user environment.'
}
