@{
    Packages = @(
        @{
            Name = 'WezTerm'
            DetectPath = '%LOCALAPPDATA%\Programs\WezTerm-nightly\wezterm.exe'
            DetectCommand = 'wezterm'
            WingetId = 'wez.wezterm.nightly'
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
        @{
            Name = 'mise'
            DetectCommand = 'mise'
            WingetId = 'jdx.mise'
            Chocolatey = 'mise'
        }
    )
}
