Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$brewfile = Join-Path $repoRoot 'linux\Brewfile'
$installer = Join-Path $repoRoot 'linux\install.sh'

$brewfileText = Get-Content -LiteralPath $brewfile -Raw
if ($brewfileText -match 'wezterm') {
    throw 'linux/Brewfile must not install WezTerm through Linuxbrew; native Ubuntu uses the official APT repository.'
}

$installerText = Get-Content -LiteralPath $installer -Raw
foreach ($pattern in @('https://apt.fury.io/wez/', 'apt-get install wezterm', 'remove_linuxbrew_wezterm')) {
    if ($installerText -notmatch [regex]::Escape($pattern)) {
        throw "linux/install.sh must manage native Linux WezTerm through APT: $pattern."
    }
}

if ($installerText -match 'if \[\[ "\$TARGET" == "wsl" \]\]; then\s*persist_bash_handoff_block') {
    throw 'linux/install.sh must append the interactive bash handoff block for both native Linux and WSL.'
}

if ($installerText -notmatch "(?m)^\s{2}persist_shell_handoff_blocks$") {
    throw 'linux/install.sh must call persist_shell_handoff_blocks during shared config wiring.'
}

foreach ($pattern in @('uses_zsh_shell', 'persist_zsh_handoff_block', '[[ -o interactive ]]')) {
    if ($installerText -notmatch [regex]::Escape($pattern)) {
        throw "linux/install.sh must support zsh login shell handoff: $pattern."
    }
}
