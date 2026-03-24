# WezTerm NuShell Bootstrap Implementation Plan

**Goal:** Keep the repository aligned with the current `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` baseline on both Windows and macOS.

**Architecture:** Shared UX assets live under `shared/`, while OS-specific installers live under `windows/` and `mac/`. `WezTerm` launches `nu -l` on both platforms. NuShell configuration is deployed into the platform-standard config directory, while `Starship` and `zoxide` autoload files are generated during installation. The prompt baseline uses the `Starship` left prompt, disables NuShell's built-in `vi` indicators and right-prompt path, and disables `shell_integration.osc133` on Windows for redraw stability under WezTerm.

**Tech Stack:** WezTerm, NuShell, Starship, zoxide, fzf, Neovim/LazyVim, Lua, PowerShell, Bash, Markdown, winget, Chocolatey, Homebrew

---

### Task 1: Maintain The Shared Asset Layout

**Files:**
- `shared/nushell/config.nu`
- `shared/nushell/env.nu`
- `shared/nushell/login.nu`
- `shared/nushell/autoload/wezterm-integration.nu`
- `shared/starship/starship.toml`
- `shared/wezterm/wezterm.lua`
- `shared/nvim/**`
- `shared/fonts/**`

**Checks:**

- Shared assets stay grouped under `shared/`
- NuShell keeps the current prompt and integration policy
- WezTerm keeps the existing visual contract
- Neovim and font assets remain source-of-truth snapshots

### Task 2: Keep WezTerm Aligned With The NuShell Baseline

**Files:**
- `shared/wezterm/wezterm.lua`

**Checks:**

- Windows launches `nu.exe -l`
- macOS launches `nu -l`
- Existing fonts, color scheme, opacity, padding, and tab/pane UX stay intact
- The Windows path fallback for NuShell still points to the standard install location

### Task 3: Keep The Windows Installer Aligned

**Files:**
- `windows/packages.psd1`
- `windows/install.ps1`

**Checks:**

- `NuShell` remains a first-class package
- Managed assets are staged into `%USERPROFILE%\.config\terminal-bootstrap`
- NuShell files are deployed into `%APPDATA%\nushell`
- `starship.nu` and `zoxide.nu` are generated into the NuShell `autoload` directory
- The installer still uses `pwsh` only as the installer runner, not as the interactive shell baseline

**Verification command:**

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

### Task 4: Keep The macOS Installer Aligned

**Files:**
- `mac/Brewfile`
- `mac/install.sh`

**Checks:**

- `nushell` remains part of the Homebrew baseline
- Managed assets are staged into `~/.config/terminal-bootstrap`
- NuShell files are deployed into `~/Library/Application Support/nushell`
- `starship.nu` and `zoxide.nu` are generated into the NuShell `autoload` directory
- Homebrew remains the package source and installer path, not the interactive shell baseline

**Verification command:**

```bash
./mac/install.sh --dry-run
```

### Task 5: Keep Documentation Aligned With The Current Baseline

**Files:**
- `README.md`
- `docs/windows-setup.md`
- `docs/mac-setup.md`
- `docs/ux-contract.md`
- `docs/troubleshooting.md`
- `docs/plans/wezterm-nushell-bootstrap-design.md`
- `docs/plans/wezterm-nushell-bootstrap.md`
- `shared/fonts/README.md`
- `shared/nvim/README.md`

**Checks:**

- Documentation stays in English
- The docs describe only the current NuShell-first baseline
- Windows docs explain why `shell_integration.osc133` is disabled
- Prompt behavior is documented as a single left `Starship` prompt with NuShell `vi` indicators disabled
- `pwsh` is described only as the Windows installer entrypoint where relevant

### Task 6: Verification

**Repository checks:**

```powershell
rg -n -P "\p{Hangul}" README.md docs shared/fonts/README.md shared/nvim/README.md
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

Run a repository grep for legacy shell references while excluding this plan document itself.

```bash
./mac/install.sh --dry-run
```

**Manual smoke tests:**

- Launch WezTerm
- Confirm that NuShell starts immediately
- Confirm that the Starship prompt renders correctly
- Confirm that `zoxide`, `fzf`, and `nvim` work
- Confirm that new tabs and splits continue the expected working flow
- On Windows, confirm that typing in WezTerm no longer shifts previous output upward
