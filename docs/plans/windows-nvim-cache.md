# Windows Neovim Cache Path Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set Windows-only aqua root and Neovim cache defaults that avoid Lua loader path length failures with aqua-managed Neovim.

**Architecture:** Windows installer persists `AQUA_ROOT_DIR=%SystemDrive%\.aqua` and `XDG_CACHE_HOME=%USERPROFILE%\.cache` for fresh processes. The shared NuShell env adds the same fallbacks only inside the Windows branch so stale GUI-launched sessions still inherit a short aqua runtime root and safe cache root without changing macOS or Linux behavior.

**Tech Stack:** PowerShell installer, NuShell env config, Markdown docs, aqua-managed Neovim.

---

### Task 1: Add Failing Tests

**Files:**
- Create: `tests/installers/windows-xdg-cache-home.ps1`
- Create: `tests/installers/windows-aqua-root-dir.ps1`
- Create: `tests/nushell/windows-xdg-cache-home.ps1`
- Create: `tests/nushell/windows-xdg-cache-home.nu`
- Create: `tests/nushell/windows-aqua-root-dir.ps1`
- Create: `tests/nushell/windows-aqua-root-dir.nu`

**Step 1: Write installer test**

Read `windows/install.ps1` and assert it contains explicit `AQUA_ROOT_DIR` and `XDG_CACHE_HOME` handling in `Set-UserEnvironmentDefaults`.

**Step 2: Write NuShell env test**

Run `shared/nushell/env.nu` with temporary Windows-style roots, no existing `AQUA_ROOT_DIR` or `XDG_CACHE_HOME`, and assert the env file sets them to the managed defaults.

**Step 3: Verify RED**

Run:

```powershell
pwsh -NoProfile -File .\tests\installers\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\installers\windows-aqua-root-dir.ps1
pwsh -NoProfile -File .\tests\nushell\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\nushell\windows-aqua-root-dir.ps1
```

Expected: both fail because the behavior is not implemented yet.

### Task 2: Implement Windows Defaults

**Files:**
- Modify: `windows/install.ps1`
- Modify: `shared/nushell/env.nu`

**Step 1: Update installer**

In `Set-UserEnvironmentDefaults`, set user `AQUA_ROOT_DIR` to `Join-Path $env:SystemDrive '.aqua'` and user `XDG_CACHE_HOME` to `Join-Path $HOME '.cache'` when the current user values are empty.

**Step 2: Update NuShell**

Inside the Windows branch, set `$env.AQUA_ROOT_DIR` to `%SystemDrive%\.aqua` and `$env.XDG_CACHE_HOME` to `$HOME\.cache` or `$USERPROFILE\.cache` only when they are empty.

**Step 3: Verify GREEN**

Run:

```powershell
pwsh -NoProfile -File .\tests\installers\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\installers\windows-aqua-root-dir.ps1
pwsh -NoProfile -File .\tests\nushell\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\nushell\windows-aqua-root-dir.ps1
```

Expected: both pass.

### Task 3: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/windows-setup.md`
- Modify: `docs/plans/README.md`

**Step 1: Document Windows cache baseline**

Mention that Windows manages `AQUA_ROOT_DIR=%SystemDrive%\.aqua` so aqua-managed Neovim runtime paths stay short, and `XDG_CACHE_HOME=%USERPROFILE%\.cache` so Neovim cache files avoid long `%LOCALAPPDATA%\Temp` paths.

**Step 2: Verify docs mention cache behavior**

Run:

```powershell
rg -n "AQUA_ROOT_DIR|XDG_CACHE_HOME|Neovim cache|Lua loader" README.md docs/windows-setup.md docs/plans/README.md
```

Expected: relevant references are present.

### Task 4: End-to-End Verification

**Files:**
- No additional file changes.

**Step 1: Run focused tests**

```powershell
pwsh -NoProfile -File .\tests\installers\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\installers\windows-aqua-root-dir.ps1
pwsh -NoProfile -File .\tests\nushell\windows-xdg-cache-home.ps1
pwsh -NoProfile -File .\tests\nushell\windows-aqua-root-dir.ps1
pwsh -NoProfile -File .\tests\nushell\starship-env.ps1
pwsh -NoProfile -File .\tests\nushell\aqua-env.ps1
```

Expected: all pass.

**Step 2: Verify Neovim with the intended cache root**

```powershell
$env:AQUA_ROOT_DIR = Join-Path $env:SystemDrive '.aqua'
$env:XDG_CACHE_HOME = Join-Path $HOME '.cache'
nvim --headless README.md +qa
```

Expected: exits with code 0.
