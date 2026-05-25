Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'windows\install.ps1'
$content = Get-Content -LiteralPath $installer -Raw

if ($content -notmatch [regex]::Escape('AQUA_ROOT_DIR')) {
    throw 'Expected windows installer to manage user AQUA_ROOT_DIR.'
}

if ($content -notmatch [regex]::Escape("Join-Path `$env:SystemDrive '.aqua'")) {
    throw 'Expected windows installer to use a short system-drive aqua root.'
}

if ($content -notmatch '\[Environment\]::SetEnvironmentVariable\(''AQUA_ROOT_DIR''') {
    throw 'Expected windows installer to persist AQUA_ROOT_DIR in the user environment.'
}
