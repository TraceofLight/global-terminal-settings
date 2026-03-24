# Troubleshooting

## WezTerm Starts But NuShell Does Not Launch

Check:

- Whether `nu` is installed
- Whether `%APPDATA%\nushell\config.nu` exists on Windows
- Whether `~/Library/Application Support/nushell/config.nu` exists on macOS
- Whether `~/.wezterm.lua` points to the managed configuration file

Actions:

- Re-run the installer to re-sync the NuShell configuration files
- If the `NuShell` package is missing, restart from the package stage
- On Windows, verify that `C:\Users\<user>\AppData\Local\Programs\nu\bin\nu.exe` actually exists

## Nu Command Is Missing In The Current Shell

Cause:

- Package installation finished, but the current shell session has not picked up the updated `PATH`

Actions:

- Open a fresh terminal session and try again
- WezTerm checks the common install path first, so it may still launch `nu` correctly even if the current shell has stale `PATH` data

## WezTerm Output Moves Up While Typing In NuShell

Cause:

- On Windows, NuShell's default `shell_integration.osc133` prompt markers can interfere with redraw behavior in WezTerm

Actions:

- Confirm that [shared/nushell/config.nu](../shared/nushell/config.nu) keeps `shell_integration.osc133 = false`
- Fully restart both WezTerm and the NuShell session after changing the config
- The repository baseline keeps `osc133` off while leaving the rest of the terminal integration in place

## Starship Or zoxide Does Not Load In NuShell

Check:

- Whether `starship.nu` and `zoxide.nu` were generated in the NuShell `autoload` directory
- Whether the `starship` and `zoxide` binaries are actually present in `PATH`
- Whether `config.nu` explicitly sources the generated autoload files

Actions:

- Re-run the installer to regenerate the autoload files
- Confirm that the package manager installed the underlying CLIs
- On macOS, confirm that [shared/nushell/env.nu](../shared/nushell/env.nu) prepends the common Homebrew bin directories before fully restarting WezTerm

## Font Does Not Appear In WezTerm

Check:

- Whether the font files exist under `~/.config/terminal-bootstrap/fonts/MonoplexKRWideNerd/`
- Whether WezTerm was fully restarted after installation
- Whether the font family names in `wezterm.lua` still match the real font metadata

Actions:

- Keep the `font_with_fallback` candidates intact
- The managed family name is `Monoplex KR Wide Nerd`
- Confirm that at least the `Regular`, `Bold`, and `Italic` variants were staged
- Use `wezterm ls-fonts` to inspect actual font discovery

## Symlink Creation Fails

Cause:

- Windows privilege restrictions
- Platform-specific symlink constraints

Actions:

- The installer falls back to copy mode when link creation fails
- The docs intentionally keep both the link path and the copy fallback

## LazyVim Starts But Tools Are Missing

Cause:

- The configuration was deployed, but external executables are still missing
- Neovim-managed tools were not rebuilt yet

Actions:

- Separate system-level tool installation from Neovim-managed tool installation
- Treat `shared/nvim` as configuration only and regenerate caches and tools in the target environment

## Windows Package Install Falls Back To Chocolatey

Cause:

- The package is missing from `winget`, or the `winget` manifest quality is not acceptable
- The package policy explicitly allows a fallback for that item

Actions:

- Keep package ownership exclusive to a single manager
- Use `choco` only as a fallback and keep `winget` as the default path
