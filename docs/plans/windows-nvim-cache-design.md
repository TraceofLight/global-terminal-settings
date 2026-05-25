# Windows Neovim Aqua Root and Cache Path Design

## Goal

Prevent aqua-managed Neovim on Windows from failing to load Lua modules when Neovim's Lua loader writes cache files for long runtime paths.

## Approach

The failure is caused by Windows path length pressure, not by LazyVim or Trouble configuration. The root cause is aqua's default runtime path under `%LOCALAPPDATA%\aquaproj-aqua\pkgs\github_release\...`; Neovim then encodes that long runtime path into Lua loader cache filenames.

The Windows baseline should set a short aqua root, `%SystemDrive%\.aqua`, so aqua-managed Neovim runs from a shorter runtime path. It should also keep the shorter XDG cache root so Neovim writes `stdpath("cache")` under `%USERPROFILE%\.cache\nvim` instead of `%LOCALAPPDATA%\Temp\nvim`.

The installer persists both user-level defaults for PowerShell, `cmd`, GUI launches, and fresh terminal sessions. The NuShell environment keeps the same Windows-only fallbacks for sessions that start before the user environment refreshes or are launched by tools with stale environment blocks.

## Components

- `windows/install.ps1`: set user `AQUA_ROOT_DIR` to `%SystemDrive%\.aqua` and user `XDG_CACHE_HOME` to `%USERPROFILE%\.cache` when the user has not chosen custom values.
- `shared/nushell/env.nu`: on Windows only, fill empty `$env.AQUA_ROOT_DIR` with `%SystemDrive%\.aqua` and empty `$env.XDG_CACHE_HOME` with `$HOME\.cache` or `$USERPROFILE\.cache`.
- `docs/windows-setup.md` and `README.md`: document the managed aqua root, cache root, and Neovim/LazyVim rationale.

## OS Scope

Only Windows receives new behavior. macOS and Linux already resolve Neovim cache paths through their normal XDG/default cache locations, and this change does not modify their installers or NuShell branches.

## Verification

- Windows installer tests check that the installer contains the user-level `AQUA_ROOT_DIR` and `XDG_CACHE_HOME` defaults.
- NuShell env tests run `shared/nushell/env.nu` with temporary Windows-style roots and verify `AQUA_ROOT_DIR` and `XDG_CACHE_HOME` are populated.
- A local Neovim check verifies LazyVim can open a Markdown file when `AQUA_ROOT_DIR=%SystemDrive%\.aqua`.
