# WezTerm NuShell Bootstrap Design

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

The shared baseline stack is fixed as follows.

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `fzf`, `zoxide`
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
- `shared/nushell/autoload/`
- `shared/nushell/wezterm-integration.nu`

The staging root is `~/.config/terminal-bootstrap/` on both OS targets.

### 7. Documentation Model

Windows and macOS documentation use the same stages and the same numbering.

1. Package manager readiness
2. Core packages
3. Stage managed assets
4. Wire WezTerm
5. Wire NuShell
6. Wire Starship, zoxide, and fzf
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
