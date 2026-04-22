# WezTerm NuShell Bootstrap Design

> **Status:** Archived historical record. Kept as-is — later revisions did not edit the original plan.
>
> **Diverged from shipped code:**
> - Linux and WSL targets were added after this design; see the adjacent `linux-wsl-support*.md`.
> - The Windows Neovim deploy target moved from `%LOCALAPPDATA%\nvim` to `%USERPROFILE%\.config\nvim` for XDG alignment.
> - Backup naming dropped its timestamp suffix; each run overwrites `<target>.pre-terminal-bootstrap`, keeping one snapshot per target.
> - The `$os` prompt indicator and the `$git_branch` symbol were introduced after this design.
>
> **Current source of truth:** `shared/`, `windows/install.ps1`, `mac/install.sh`, `docs/ux-contract.md`.

**Date:** 2026-03-25

## Goal

Redefine the bootstrap structure so Windows and macOS can reproduce the same `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` terminal, shell, and editor environment.

## Constraints

- The scope is limited to the terminal, shell, and editor environment
- C/C++ compilers and build toolchains are out of scope
- Windows should default to native package installation
- Windows and macOS must expose the same user experience and document structure
- OS-specific implementation differences are allowed, but stage numbers and meanings must stay aligned
- Existing `LazyVim`, `WezTerm`, and `Starship` customizations must be preserved
- Documentation should describe the current baseline only, without migration history or superseded assumptions

## Decisions

### 1. Platform Model

The shared baseline stack is fixed as follows and applies to Windows, macOS, native Ubuntu Linux, and WSL Ubuntu. WSL is a reduced install that defers the WezTerm UI layer to the Windows host; see `linux-wsl-support-design.md` for the target-specific differences.

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `fzf`, `zoxide`
- Command completion: `carapace`
- Optional CLI extern layers: `claude`, `openclaude` (wired only when the CLI is present)
- Editor: `Neovim + LazyVim`

Shared consistency is defined by user experience, not by shell binary compatibility.

- The same WezTerm visual design
- The same NuShell entry flow
- The same prompt structure
- The same navigation and search tools
- The same Neovim configuration

### 2. Package Strategy

Windows and macOS both source external CLI tools from native package managers.

- Windows primary package manager: `winget`
- Windows fallback package manager: `choco`
- macOS primary package manager: `brew`

Windows follows these rules.

- Install baseline packages with `winget`
- Use `choco` only when `winget` is missing the package or the manifest quality is unacceptable
- Keep ownership of each package exclusive to one manager

CLI tools are treated as installed external executables, not as shell features.

### 3. Shell Model

Both OS targets set `WezTerm` to launch `nu -l` by default.

NuShell initialization responsibilities are split across the following files.

- `login.nu`: one-time session bootstrap work
- `env.nu`: environment variables and path policy
- `config.nu`: interactive behavior, aliases, keybindings, and hooks

Third-party initialization is organized through the standard NuShell autoload layer.

Prompt rendering behavior is also defined explicitly in `config.nu`.

- Use the `Starship` left prompt as the canonical prompt path
- Disable NuShell's built-in `vi` indicators and multiline indicator
- Do not use the NuShell right-prompt path
- Disable `shell_integration.osc133` on Windows when running under WezTerm

### 4. WezTerm Integration Model

Keep the existing WezTerm appearance and tab/split UX. Changes are limited to the shell entrypoint and the NuShell integration layer.

The NuShell-specific WezTerm integration is maintained as a separate Nu module.

- Track working-directory changes through `env_change.PWD`
- Emit `OSC 7` for WezTerm
- Do not use the `pre_prompt` path that interferes with redraw behavior

The goal is not identical implementation mechanics, but identical user-facing behavior.

### 5. Customization Preservation Policy

Existing repository customizations are treated as preserved assets.

- `shared/nvim/` keeps the current `LazyVim` snapshot intact
- `shared/starship/starship.toml` keeps the existing prompt structure and information layout
- `shared/wezterm/wezterm.lua` keeps the visual style, fonts, and tab/pane behavior
- `fzf`, `zoxide`, `rg`, `fd`, `git`, and `nvim` keep their current roles

The only accepted learning cost is NuShell syntax and command semantics. Other workflow changes are treated as regressions.

### 6. File Layout

Shared assets live under `shared/`.

- `shared/wezterm/`
- `shared/nushell/`
- `shared/starship/`
- `shared/nvim/`
- `shared/fonts/`

NuShell assets follow this structure.

- `shared/nushell/config.nu`
- `shared/nushell/env.nu`
- `shared/nushell/login.nu`
- `shared/nushell/autoload/wezterm-integration.nu`
- `shared/nushell/autoload/claude-integration.nu`
- `shared/nushell/autoload/openclaude-integration.nu`

The staging root is `~/.config/terminal-bootstrap/` on both OS targets. The live NuShell config root is `~/.config/nushell/` on both OS targets. WezTerm sets `XDG_CONFIG_HOME=~/.config` so the running NuShell process resolves its config from the same location that the installer writes to, and on Windows a compatibility junction at `%APPDATA%\nushell` points at the same directory.

### 7. Documentation Model

Windows and macOS documentation use the same stages and the same numbering.

1. Package manager readiness
2. Core packages
3. Stage managed assets
4. Wire WezTerm
5. Wire NuShell
6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration
7. Sync LazyVim
8. Verify

OS-specific docs and installers share these stage names, while the concrete commands and package sources remain platform-specific.

### 8. Verification Model

Verification is defined in user-visible terms.

- WezTerm opens directly into a NuShell session
- The Starship prompt renders in the intended shape
- `zoxide` navigation works
- `fzf` can be invoked
- `nvim` opens with the existing configuration
- New tabs and splits inherit the working flow naturally

## Deliverables

- Shared NuShell assets
- NuShell-based WezTerm configuration
- Windows installation guide
- macOS installation guide
- Shared UX contract
- Troubleshooting guide
- NuShell-centered installer structure
- Verification procedure documentation

## Non-Goals

- Compiler or build toolchain installation
- Per-language development environment automation
- Preserving shell compatibility layers
- Documenting parallel operation with superseded structures
