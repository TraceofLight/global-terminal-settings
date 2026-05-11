@{
    Packages = @(
        @{
            Name = 'WezTerm'
            DetectCommand = 'wezterm'
            WingetId = 'wez.wezterm'
            Chocolatey = 'wezterm.install'
        }
        @{
            Name = 'NuShell'
            DetectPath = '%LOCALAPPDATA%\Programs\nu\bin\nu.exe'
            DetectCommand = 'nu'
            WingetId = 'Nushell.Nushell'
            Chocolatey = 'nushell'
        }
        @{
            Name = 'Git'
            DetectCommand = 'git'
            WingetId = 'Git.Git'
            Chocolatey = 'git.install'
        }
        @{
            Name = 'aqua'
            DetectCommand = 'aqua'
            WingetId = 'aquaproj.aqua'
            Chocolatey = 'aqua'
        }
    )
}
