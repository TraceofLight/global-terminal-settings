@{
    Packages = @(
        @{
            Name = 'WezTerm'
            DetectCommand = 'wezterm'
            WingetId = 'wez.wezterm'
            Chocolatey = 'wezterm.install'
        }
        @{
            Name = 'MSYS2'
            DetectPath = '%SystemDrive%\msys64\usr\bin\bash.exe'
            WingetId = 'MSYS2.MSYS2'
            Chocolatey = 'msys2'
        }
        @{
            Name = 'Git'
            DetectCommand = 'git'
            WingetId = 'Git.Git'
            Chocolatey = 'git.install'
        }
        @{
            Name = 'Neovim'
            DetectCommand = 'nvim'
            WingetId = 'Neovim.Neovim'
            Chocolatey = 'neovim'
        }
        @{
            Name = 'Starship'
            DetectCommand = 'starship'
            WingetId = 'Starship.Starship'
            Chocolatey = 'starship.install'
        }
        @{
            Name = 'ripgrep'
            DetectCommand = 'rg'
            WingetId = 'BurntSushi.ripgrep.MSVC'
            Chocolatey = 'ripgrep'
        }
        @{
            Name = 'fd'
            DetectCommand = 'fd'
            WingetId = 'sharkdp.fd'
            Chocolatey = 'fd'
        }
        @{
            Name = 'bat'
            DetectCommand = 'bat'
            WingetId = 'sharkdp.bat'
            Chocolatey = 'bat'
        }
        @{
            Name = 'zoxide'
            DetectCommand = 'zoxide'
            WingetId = 'ajeetdsouza.zoxide'
            Chocolatey = 'zoxide'
        }
        @{
            Name = 'lazygit'
            DetectCommand = 'lazygit'
            WingetId = 'JesseDuffield.lazygit'
            Chocolatey = 'lazygit'
        }
        @{
            Name = 'delta'
            DetectCommand = 'delta'
            WingetId = 'dandavison.delta'
            Chocolatey = 'delta'
        }
        @{
            Name = 'fastfetch'
            DetectCommand = 'fastfetch'
            WingetId = 'Fastfetch-cli.Fastfetch'
            Chocolatey = 'fastfetch'
        }
        @{
            Name = 'fzf'
            DetectCommand = 'fzf'
            WingetId = 'junegunn.fzf'
            Chocolatey = 'fzf'
        }
        @{
            Name = 'dust'
            DetectCommand = 'dust'
            WingetId = 'bootandy.dust'
            Chocolatey = 'dust'
        }
        @{
            Name = 'duf'
            DetectCommand = 'duf'
            WingetId = 'muesli.duf'
            Chocolatey = 'duf'
        }
        @{
            Name = 'mise'
            DetectCommand = 'mise'
            WingetId = 'jdx.mise'
            Chocolatey = 'mise'
        }
        @{
            Name = 'lsd'
            DetectCommand = 'lsd'
            WingetId = 'lsd-rs.lsd'
            Chocolatey = 'lsd'
        }
        @{
            Name = 'btop4win'
            DetectCommand = 'btop'
            WingetId = 'aristocratos.btop4win'
        }
        @{
            Name = 'navi'
            DetectCommand = 'navi'
            Chocolatey = 'navi'
        }
    )
}
