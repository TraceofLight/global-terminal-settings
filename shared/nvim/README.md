# Neovim Config Snapshot

This directory is the current local Neovim configuration snapshot.

Source:

- Windows baseline: `%LOCALAPPDATA%\\nvim`

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
