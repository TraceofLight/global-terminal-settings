Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('n'))
$originalXdgConfigHome = $env:XDG_CONFIG_HOME

try {
    $configRoot = Join-Path $testRoot 'config'
    $nushellConfigRoot = Join-Path $configRoot 'nushell'
    $autoloadRoot = Join-Path $nushellConfigRoot 'autoload'

    New-Item -ItemType Directory -Force -Path $autoloadRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'shared\nushell\config.nu') -Destination (Join-Path $nushellConfigRoot 'config.nu')
    Set-Content -LiteralPath (Join-Path $nushellConfigRoot 'env.nu') -Value ''
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'shared\nushell\autoload') -Filter '*.nu' |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $autoloadRoot $_.Name)
        }

    @'
export-env { load-env {
    PROMPT_COMMAND: {||
        $env.TERMINAL_BOOTSTRAP_PROMPT_WAS_CALLED = "yes"
        "prompt should be skipped after interrupt"
    }
    PROMPT_COMMAND_RIGHT: {|| "right prompt should be disabled without a hook" }
} }
'@ | Set-Content -LiteralPath (Join-Path $autoloadRoot 'starship.nu')
    Add-Content -LiteralPath (Join-Path $autoloadRoot 'starship.nu') -Value ''
    Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'shared\nushell\autoload\zz-prompt-overrides.nu') |
        Add-Content -LiteralPath (Join-Path $autoloadRoot 'starship.nu')

    $env:XDG_CONFIG_HOME = $configRoot
    & nu -n (Join-Path $repoRoot 'tests\nushell\prompt-overrides-interrupt-status.nu')
    if ($LASTEXITCODE -ne 0) {
        throw "prompt override interrupt status test failed with exit code $LASTEXITCODE"
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -eq $originalXdgConfigHome) {
        Remove-Item Env:\XDG_CONFIG_HOME -ErrorAction SilentlyContinue
    } else {
        $env:XDG_CONFIG_HOME = $originalXdgConfigHome
    }
}
