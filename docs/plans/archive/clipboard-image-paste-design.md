# Codex Clipboard Image Paste Design

> **Status:** Archived historical record. The feature shipped and is still active; the
> `Ctrl+V`-in-an-agent-pane interception is required because Claude Code / Codex only
> attach an image when a path to it is *pasted* (a raw `Ctrl+V` keystroke does not work).
>
> **Diverged from shipped code:**
> - The helper now also handles an image **file** copied in Explorer (`Ctrl+C` → `CF_HDROP`),
>   not just a bitmap (`Win+Shift+S`); it copies the file into the temp dir. Fixed 2026-06-13.
> - It emits a forward-slash temp path; the staging dir was renamed
>   `%TEMP%\codex-clipboard` → `%TEMP%\wezterm-clipboard`.
>
> **Current source of truth:** `shared/wezterm/wezterm.lua`, `shared/wezterm/save-clipboard-image.ps1`.

## Goal

Make image clipboard paste less tedious in Windows WezTerm sessions running Codex. When the active pane is Codex and the Windows clipboard contains an image, `Ctrl+V` should save the image to a temporary PNG and paste that path into Codex.

## Approach

WezTerm keeps the behavior local to the terminal configuration. A Lua callback handles `Ctrl+V`, checks whether the foreground pane looks like Codex, and runs a PowerShell STA helper to export a Windows clipboard image to `%TEMP%\codex-clipboard\*.png`.

If the helper returns an image path, WezTerm pastes that path into the pane. If there is no clipboard image, Codex still receives normal text paste. Non-Codex panes receive a literal `Ctrl+V`, so shell and editor keybindings are not changed.

## Components

- `shared/wezterm/save-clipboard-image.ps1`: Windows-only helper that reads `System.Windows.Forms.Clipboard` and saves a PNG.
- `shared/wezterm/wezterm.lua`: Codex-scoped `Ctrl+V` callback and helper process invocation.
- Active user config copies under `~\.config\terminal-bootstrap\wezterm` and `~\.wezterm.lua` receive the same changes for immediate use.

## Error Handling

The helper prints `NO_IMAGE` and exits non-zero when there is no image or the clipboard cannot provide one. WezTerm treats that as a normal fallback path and performs text paste for Codex.

## Verification

- Confirm the old config lacks the helper and callback.
- Run the helper against a synthetic clipboard bitmap and verify a PNG is created.
- Run the helper when the clipboard contains text and verify it reports no image.
- Load the updated WezTerm config with `wezterm --config-file ... show-keys --lua`.

## Update — 2026-05-22: Generalized to all agent CLIs

The original implementation scoped the `Ctrl+V` callback to Codex panes only.
Claude Code panes were never matched, so they fell through to a literal
`Ctrl+V` and relied on Claude Code's own (unreliable on native Windows)
clipboard image handling — clipboard image paste silently failed.

The detection is now agent-agnostic:

- `is_codex_pane` → `is_agent_pane`, `codex_clipboard_paste` → `agent_clipboard_paste`.
- Foreground-process match extended with `claude.exe` / `claude`. Claude Code
  2.x ships as a native binary (`~\.local\bin\claude.exe`), not under
  `node.exe`, so the marker-branch process whitelist never covered it.
- Title substring match extended with `claude`.
- The asterisk-marker (`U+2733`) fallback is unchanged — it already covers an
  agent CLI running under a generic `node.exe` / `cmd.exe` host.

Behavior is otherwise identical: any agent pane with a clipboard image gets the
temp-PNG path pasted; no image falls back to text paste; non-agent panes still
receive a literal `Ctrl+V`. The helper script and `%TEMP%\codex-clipboard`
staging directory keep their names (internal, not user-visible).
