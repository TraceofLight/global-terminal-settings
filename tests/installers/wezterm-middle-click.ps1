Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$weztermConfig = Join-Path $repoRoot 'shared\wezterm\wezterm.lua'
$configText = Get-Content -LiteralPath $weztermConfig -Raw

foreach ($pattern in @(
    'config.mouse_bindings',
    'button = "Middle"',
    'mods = "NONE"',
    'action = act.Nop'
)) {
    if ($configText -notmatch [regex]::Escape($pattern)) {
        throw "shared/wezterm/wezterm.lua must disable unmodified middle-click paste: $pattern."
    }
}
