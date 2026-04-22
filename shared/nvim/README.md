# Neovim Config Snapshot

This directory is the current local Neovim configuration snapshot.

Source:

- Windows baseline: `%USERPROFILE%\\.config\\nvim` (aligned with the user `XDG_CONFIG_HOME` that the installer sets)
- macOS baseline: `~/.config/nvim` (or `$XDG_CONFIG_HOME/nvim` when set)
- Linux baseline: `~/.config/nvim` (or `$XDG_CONFIG_HOME/nvim` when set)

Included:

- `init.lua`
- `lua/`
- `lazy-lock.json`
- Other configuration files

Excluded:

- `.git`
- `nvim-data`
- Mason-managed binaries
- Sessions, caches, undo files, and swap files

Operating policy:

- Treat this directory as the shared source-of-truth configuration
- During installation, link or copy it into the real Neovim config directory for each OS
