$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($machinePath -or $userPath) {
    $env:Path = ($machinePath, $userPath) -join ';'
}

$env:EDITOR = "nvim"
$env:VISUAL = "nvim"

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vi -Value nvim -Scope Global
    Set-Alias -Name vim -Value nvim -Scope Global
}

if (Get-Command lsd -ErrorAction SilentlyContinue) {
    function Invoke-TerminalBootstrapLs {
        & lsd @args
    }

    function Invoke-TerminalBootstrapLl {
        & lsd -l @args
    }

    function Invoke-TerminalBootstrapLa {
        & lsd -la @args
    }

    function Invoke-TerminalBootstrapLt {
        & lsd --tree @args
    }

    Set-Alias -Name ls -Value Invoke-TerminalBootstrapLs -Scope Global -Force
    Set-Alias -Name ll -Value Invoke-TerminalBootstrapLl -Scope Global -Force
    Set-Alias -Name la -Value Invoke-TerminalBootstrapLa -Scope Global -Force
    Set-Alias -Name lt -Value Invoke-TerminalBootstrapLt -Scope Global -Force
}

if (-not (Get-Command btop -ErrorAction SilentlyContinue)) {
    $btop4win = Get-Command btop4win -ErrorAction SilentlyContinue
    if ($btop4win) {
        Set-Alias -Name btop -Value btop4win -Scope Global
    }
}

$starship = Get-Command starship -ErrorAction SilentlyContinue
if ($starship) {
    Invoke-Expression ((& $starship.Source init powershell) -join [Environment]::NewLine)
}

$zoxide = Get-Command zoxide -ErrorAction SilentlyContinue
if ($zoxide) {
    Invoke-Expression ((& $zoxide.Source init powershell) -join [Environment]::NewLine)
}
