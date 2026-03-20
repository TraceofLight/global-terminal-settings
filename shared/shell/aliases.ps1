$env:EDITOR = "nvim"
$env:VISUAL = "nvim"

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vi -Value nvim -Scope Global
    Set-Alias -Name vim -Value nvim -Scope Global
}

$starship = Get-Command starship -ErrorAction SilentlyContinue
if ($starship) {
    Invoke-Expression (& $starship.Source init powershell)
}

$zoxide = Get-Command zoxide -ErrorAction SilentlyContinue
if ($zoxide) {
    Invoke-Expression (& $zoxide.Source init powershell)
}
