# Codex Clipboard Image Paste Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Windows WezTerm shortcut path that lets Codex paste image clipboard contents as temporary PNG files.

**Architecture:** WezTerm owns the keybinding and delegates Windows clipboard image extraction to a small PowerShell STA helper. The Lua callback only applies to Codex panes and falls back to existing paste behavior when no image is present.

**Tech Stack:** WezTerm Lua config, Windows PowerShell, .NET `System.Windows.Forms` clipboard APIs.

---

### Task 1: Red Checks

**Files:**
- Read: `shared/wezterm/wezterm.lua`
- Expect missing: `shared/wezterm/save-clipboard-image.ps1`

**Step 1: Verify helper is missing**

Run:

```powershell
if (Test-Path 'shared/wezterm/save-clipboard-image.ps1') { exit 0 } else { exit 1 }
```

Expected: exit 1.

**Step 2: Verify Codex callback is missing**

Run:

```powershell
if (Select-String -Path 'shared/wezterm/wezterm.lua' -Pattern 'codex_clipboard_paste|save_clipboard_image_path|action_callback' -Quiet) { exit 0 } else { exit 1 }
```

Expected: exit 1.

### Task 2: Add Helper

**Files:**
- Create: `shared/wezterm/save-clipboard-image.ps1`

**Step 1: Implement helper**

Create a PowerShell script that loads `System.Windows.Forms` and `System.Drawing`, checks `Clipboard.ContainsImage()`, saves the image to a unique PNG under `%TEMP%\codex-clipboard`, and writes `IMAGE_PATH=<path>`.

**Step 2: Verify no-image behavior**

Run the helper with a text clipboard.

Expected: `NO_IMAGE` and non-zero exit.

**Step 3: Verify image behavior**

Set a synthetic bitmap into the clipboard, run the helper, and verify the reported PNG exists.

Expected: `IMAGE_PATH=...png` and exit 0.

### Task 3: Add WezTerm Callback

**Files:**
- Modify: `shared/wezterm/wezterm.lua`

**Step 1: Add helper functions**

Add functions to detect Codex panes, run the helper, parse `IMAGE_PATH=...`, and normalize path output.

**Step 2: Add `Ctrl+V` keybinding**

Bind `{ key = "v", mods = "CTRL" }` to the callback. In Codex panes, image clipboard paths are pasted; otherwise text paste is used. In non-Codex panes, send literal `Ctrl+V`.

**Step 3: Verify config loads**

Run:

```powershell
wezterm --config-file 'shared/wezterm/wezterm.lua' show-keys --lua
```

Expected: exit 0.

### Task 4: Deploy Active Config

**Files:**
- Copy to: `%USERPROFILE%\.config\terminal-bootstrap\wezterm\wezterm.lua`
- Copy to: `%USERPROFILE%\.config\terminal-bootstrap\wezterm\save-clipboard-image.ps1`
- Copy to: `%USERPROFILE%\.wezterm.lua`

**Step 1: Deploy exact files**

Copy the repo helper and Lua config to the active WezTerm config locations.

**Step 2: Verify active config**

Run:

```powershell
wezterm --config-file "$env:USERPROFILE\.wezterm.lua" show-keys --lua
```

Expected: exit 0.
