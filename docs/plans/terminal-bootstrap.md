# Terminal Bootstrap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Windows와 mac에서 공통 터미널 UX를 재현할 수 있도록 부트스트랩 폴더, 문서, 설정 자산, 설치 스크립트를 정리한다.

**Status Update (2026-03-21):** 폴더 구조, 공통 자산, Windows/mac 설치 스크립트가 모두 작성되었다. 이 문서는 최초 구현 계획 기록으로 유지하고, 현재 운영 방식은 `README.md`와 OS별 setup 문서를 기준으로 본다.

**Architecture:** 공통 자산은 `shared/`에 두고, OS별 설치 흐름과 예외는 `windows/`, `mac/`에 분리한다. 설치는 준오프라인 방식으로 설계하며, 폰트와 설정은 폴더 내부 자산으로 보관하고 패키지는 설치 시 온라인으로 받는다.

**Tech Stack:** WezTerm, MSYS2 UCRT64, zsh, PowerShell 7, Neovim, LazyVim, Starship, Markdown, PowerShell, Bash

---

### Task 1: Bootstrap Root Scaffold

**Files:**
- Create: `README.md`
- Create: `docs/plans/terminal-bootstrap-design.md`
- Create: `docs/plans/terminal-bootstrap.md`

**Step 1: Create the root folder structure**

Run:

```powershell
New-Item -ItemType Directory -Force -Path `
  '.\docs', `
  '.\docs\plans'
```

Expected: directories are created or already exist.

**Step 2: Write the top-level README**

Document the purpose, included assets, current status, and navigation entry points.

**Step 3: Write the design document**

Capture the approved architecture and scope decisions.

**Step 4: Write the implementation plan**

Record the remaining work in executable units.

### Task 2: Shared Asset Layout

**Files:**
- Create: `shared/fonts/README.md`
- Create: `shared/nvim/README.md`
- Create: `shared/wezterm/wezterm.lua`
- Create: `shared/wezterm/wezterm-shell-integration.sh`
- Create: `shared/starship/starship.toml`
- Create: `shared/shell/aliases.sh`
- Create: `shared/shell/aliases.ps1`

**Step 1: Create the shared subdirectories**

Run:

```powershell
New-Item -ItemType Directory -Force -Path `
  '.\shared\fonts', `
  '.\shared\nvim', `
  '.\shared\wezterm', `
  '.\shared\starship', `
  '.\shared\shell'
```

Expected: directories are created.

**Step 2: Copy the bundled font source**

Copy `MonoplexKRWideNerd` into `shared/fonts/`.

**Step 3: Snapshot the current LazyVim config**

Copy the local config from `%LOCALAPPDATA%\\nvim` into `shared/nvim`, excluding `.git` and runtime data.

**Step 4: Bundle the official shell integration script**

Copy the official WezTerm shell integration script into `shared/wezterm/wezterm-shell-integration.sh`.

**Step 5: Write baseline shared config files**

Add a starter WezTerm config, Starship config, and shell alias files.

### Task 3: Operating System Documentation

**Files:**
- Create: `docs/windows-setup.md`
- Create: `docs/mac-setup.md`
- Create: `docs/ux-contract.md`
- Create: `docs/troubleshooting.md`

**Step 1: Write the Windows setup guide**

Document the future flow for WezTerm, MSYS2 UCRT64, fonts, links, and tool installation.

**Step 2: Write the mac setup guide**

Document the future flow for Homebrew, WezTerm, fonts, links, and CLI tool installation.

**Step 3: Write the UX contract**

Define what must stay consistent across both operating systems.

**Step 4: Write the troubleshooting guide**

Capture expected problem areas before implementation starts.

### Task 4: Installer Entry Point Stubs

**Files:**
- Create: `windows/install.ps1`
- Create: `mac/install.sh`

**Step 1: Create Windows installer stub**

Add a non-executing PowerShell entry point that explains its future responsibility.

**Step 2: Create mac installer stub**

Add a non-executing Bash entry point that explains its future responsibility.

**Step 3: Record deferred implementation areas**

List future subtasks inside the stubs without performing any installation.

### Task 5: Validation

**Files:**
- Verify: `.\**`

**Step 1: Verify the folder tree**

Run:

```powershell
Get-ChildItem -Recurse .
```

Expected: docs, shared assets, and OS entry points are all present.

**Step 2: Verify copied assets**

Check that `shared/fonts/MonoplexKRWideNerd` and `shared/nvim` contain expected files.

**Step 3: Verify no installation side effects occurred**

Confirm that no package manager or system installer commands were run.

**Step 4: Summarize next implementation targets**

Highlight installer implementation, symlink/copy mode, and OS-specific package lists.
