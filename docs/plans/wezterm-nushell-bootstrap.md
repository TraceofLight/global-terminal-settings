# WezTerm NuShell Bootstrap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Windows와 mac에서 `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` 기준의 공통 부트스트랩 구조와 설치 문서를 실제 파일 상태와 맞게 재구성한다.

**Architecture:** 공통 UX 자산은 `shared/`에 두고, OS별 설치 구현은 `windows/`, `mac/`에 분리한다. `WezTerm`은 양쪽 모두 `nu -l`을 기본 진입점으로 사용하고, NuShell 설정은 표준 디렉터리에 배치하되, `Starship`과 `zoxide`의 NuShell 초기화 파일은 설치 시 autoload 계층에 생성한다.

**Tech Stack:** WezTerm, NuShell, Starship, zoxide, fzf, Neovim/LazyVim, Lua, PowerShell, Bash, Markdown, winget, Chocolatey, Homebrew

---

### Task 1: Replace Shared Shell Baseline

**Files:**
- Delete: `shared/shell/aliases.sh`
- Delete: `shared/shell/aliases.ps1`
- Delete: `shared/wezterm/wezterm-shell-integration.sh`
- Delete: `shared/tmux/.tmux.conf`
- Create: `shared/nushell/config.nu`
- Create: `shared/nushell/env.nu`
- Create: `shared/nushell/login.nu`
- Create: `shared/nushell/autoload/wezterm-integration.nu`

**Step 1: Capture the old shell references**

Run:

```powershell
rg -n "tmux|bash|zsh|pwsh|wezterm-shell-integration" shared docs README.md
```

Expected: the current tree still reports the old shell baseline.

**Step 2: Create the NuShell baseline files**

Add `config.nu`, `env.nu`, `login.nu`, and `autoload/wezterm-integration.nu` to `shared/nushell/`.

**Step 3: Remove obsolete shared shell files**

Delete the old shell alias files, WezTerm shell integration script, and tmux config file.

**Step 4: Verify the tree shape**

Run:

```powershell
Get-ChildItem shared -Recurse
```

Expected: `shared/nushell/` exists and the deleted shell/tmux files are gone.

### Task 2: Update WezTerm To Launch NuShell

**Files:**
- Modify: `shared/wezterm/wezterm.lua`

**Step 1: Verify the current default shell logic**

Run:

```powershell
rg -n "default_prog|MSYS2_PATH_TYPE|msys2|pwsh|zsh" shared/wezterm/wezterm.lua
```

Expected: the current file still points at the previous shell logic.

**Step 2: Replace the default shell entrypoint**

Set the Windows entrypoint to `nu.exe -l` and the mac entrypoint to `nu -l` while keeping the existing visual settings intact.

**Step 3: Keep the current visual contract**

Preserve fonts, color scheme, opacity, padding, tab behavior, and clipboard/split keymaps.

**Step 4: Verify the edited file**

Run:

```powershell
Get-Content shared/wezterm/wezterm.lua
```

Expected: the file still contains the existing appearance settings and now launches NuShell.

### Task 3: Rebuild The Windows Installer Around NuShell

**Files:**
- Modify: `windows/packages.psd1`
- Modify: `windows/install.ps1`

**Step 1: Replace the package baseline**

Update `windows/packages.psd1` so that `NuShell` is a first-class package and the package list remains native-first.

**Step 2: Remove the old shell-profile path**

Drop `.bashrc`, `.bash_profile`, and PowerShell profile management from `windows/install.ps1`.

**Step 3: Add NuShell config deployment**

Stage `shared/nushell/` into the managed install root, then link or copy `config.nu`, `env.nu`, `login.nu`, and `autoload/wezterm-integration.nu` into `%APPDATA%\nushell`.

**Step 4: Generate NuShell autoload files**

Generate `starship.nu` and `zoxide.nu` in `%APPDATA%\nushell\autoload` during the config phase.

**Step 5: Verify the Windows dry-run**

Run:

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

Expected: the stage log shows the shared 8-step structure and references NuShell instead of the old shell baseline.

### Task 4: Rebuild The mac Installer Around NuShell

**Files:**
- Modify: `mac/Brewfile`
- Modify: `mac/install.sh`

**Step 1: Replace the package baseline**

Add `nushell` to `mac/Brewfile` and remove packages that only supported the previous shell baseline.

**Step 2: Remove shell-profile management**

Drop `.zshrc` injection from `mac/install.sh`.

**Step 3: Add NuShell config deployment**

Stage `shared/nushell/` into the managed install root, then link or copy the config files into `~/Library/Application Support/nushell`.

**Step 4: Generate NuShell autoload files**

Generate `starship.nu` and `zoxide.nu` in the NuShell autoload directory during the config phase.

**Step 5: Verify the mac dry-run**

Run:

```bash
./mac/install.sh --dry-run
```

Expected: the stage log shows the shared 8-step structure and references NuShell instead of the old shell baseline.

### Task 5: Rewrite The Installation Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/windows-setup.md`
- Modify: `docs/mac-setup.md`
- Modify: `docs/ux-contract.md`
- Modify: `docs/troubleshooting.md`

**Step 1: Rewrite the README**

Describe the new stack, folder layout, staging model, and the new design/plan entry points.

**Step 2: Rewrite the Windows setup guide**

Align it to the shared 8-step structure and the actual Windows installer behavior.

**Step 3: Rewrite the mac setup guide**

Align it to the shared 8-step structure and the actual mac installer behavior.

**Step 4: Rewrite the UX contract and troubleshooting docs**

Update both files to reflect the NuShell-first, native-package baseline.

**Step 5: Remove references to the previous shell baseline**

Run:

```powershell
rg -n "tmux|MSYS2 UCRT64 bash|pwsh|zsh|wezterm-shell-integration|bashrc|bash_profile" README.md docs
```

Expected: the grep no longer reports stale shell-baseline references in the main docs.

### Task 6: Final Verification

**Files:**
- Verify: `README.md`
- Verify: `docs/**`
- Verify: `shared/**`
- Verify: `windows/**`
- Verify: `mac/**`

**Step 1: Inspect git status**

Run:

```powershell
git status --short
```

Expected: only the intended NuShell/WezTerm redesign files are modified.

**Step 2: Verify Windows dry-run**

Run:

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

Expected: no PowerShell parse errors and the stage log is readable.

**Step 3: Verify mac dry-run**

Run:

```bash
./mac/install.sh --dry-run
```

Expected: no shell parse errors and the stage log is readable.

**Step 4: Summarize manual smoke tests**

Record the remaining manual checks:

- Launch WezTerm
- Confirm NuShell starts
- Confirm Starship renders
- Confirm `zoxide`, `fzf`, `nvim` work
- Confirm new tabs and splits open in the expected flow
