# Prompt OS Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a left-most OS indicator segment to the shared Starship prompt so macOS, native Linux, WSL Ubuntu, and Windows-native NuShell sessions are visually distinguishable at a glance.

**Architecture:** Enable Starship's built-in `$os` module in the shared `shared/starship/starship.toml`, prepend it to `format` as a new `peach`-backgrounded powerline segment, and define a minimal `[os.symbols]` table covering the OSes this repo targets (macOS, Ubuntu, Debian, generic Linux, Windows). Update `docs/ux-contract.md` so the UX contract documents the new leftmost segment.

**Tech Stack:** Starship, TOML, Nerd Font glyphs (Monoplex KR Wide Nerd), Markdown

---

### Task 1: Add `$os` segment to `shared/starship/starship.toml`

**Files:**
- Modify: `shared/starship/starship.toml`

**Acceptance Criteria:**
- [ ] `format` starts with the new peach-backgrounded OS segment followed by a `peach→mauve` powerline transition before `$directory`
- [ ] `[os]` section sets `disabled = false`, `style = "bg:peach fg:crust"`, and `format = "[ $symbol ]($style)"`
- [ ] `[os.symbols]` maps `Macos`, `Ubuntu`, `Debian`, `Linux`, and `Windows` to Nerd Font glyphs
- [ ] Existing palette, `[directory]`, `[git_branch]`, `[git_status]`, `[cmd_duration]`, and `[character]` sections are untouched
- [ ] `starship print-config` parses the file without error when pointed at it

**Verify:**

```bash
STARSHIP_CONFIG="$(pwd)/shared/starship/starship.toml" starship print-config | head -n 40
```

Expected: output begins with the header `"$schema"` / `format` / `add_newline` / `palette` entries, the rendered `format` value starts with the `` cap and references `$os`, and no `[ERROR]` or parse diagnostic appears on stderr.

- [ ] **Step 1: Replace the `format` block**

In `shared/starship/starship.toml`, find the existing `format` assignment spanning lines 5-14 (opens with `format = """` and closes with `"""`). Replace the entire assignment with:

```toml
format = """
[](peach)\
$os\
[](fg:peach bg:mauve)\
$directory\
[](fg:mauve bg:blue)\
$git_branch\
$git_status\
[](fg:blue) \
$cmd_duration\
$character\
"""
```

The only change vs. the current value is the two new leading lines (`[](peach)\` and `$os\`) plus the new `[](fg:peach bg:mauve)\` transition cap inserted before `$directory\`. Every other line must remain byte-identical to the current file, including the trailing backslashes and the literal space preserved in `[](fg:blue) \` (space before the backslash).

- [ ] **Step 2: Append the `[os]` section**

After the existing `[character]` section (the last block in the file), append a blank line and the following:

```toml

[os]
disabled = false
style = "bg:peach fg:crust"
format = "[ $symbol ]($style)"

[os.symbols]
Macos = ""
Ubuntu = ""
Debian = ""
Linux = ""
Windows = ""
```

The glyphs are, in order, Nerd Font codepoints U+F302 (apple), U+F31B (ubuntu), U+F306 (debian), U+F17C (tux), U+F17A (windows). Copy them literally from this file — do not retype from a palette picker.

- [ ] **Step 3: Validate the TOML parses**

Run:

```bash
STARSHIP_CONFIG="$(pwd)/shared/starship/starship.toml" starship print-config
```

Expected: command exits 0 and prints a TOML dump whose `format` value begins with the peach cap segment and contains `$os`. If the command errors (e.g., "invalid escape sequence", "expected table header"), re-inspect the file — most likely a stray space inside the multiline `format` string or a missing blank line before the new `[os]` section.

- [ ] **Step 4: Visual smoke check in the current environment**

Launch a fresh NuShell session (or `exec nu -l` from the current one) and confirm the leftmost prompt segment shows a peach block containing the glyph matching the host (`` on macOS, `` on Ubuntu/WSL-Ubuntu, `` on Windows native nu). If the glyph appears as a box/tofu, the session is not using Monoplex KR Wide Nerd — that is a font-loading issue outside the scope of this task and should be noted but not blocked on.

- [ ] **Step 5: Commit**

```bash
git add shared/starship/starship.toml
git commit --only shared/starship/starship.toml -m "feat(starship): add OS indicator segment to shared prompt"
```

The `--only <path>` form is intentional — other unrelated files may be staged in the working copy and must not be pulled into this commit.

---

### Task 2: Document the OS indicator in `docs/ux-contract.md`

**Files:**
- Modify: `docs/ux-contract.md:44-51`

**Acceptance Criteria:**
- [ ] "Prompt Policy" section gains one bullet stating the leftmost segment is the current OS symbol
- [ ] No other section of `ux-contract.md` is modified
- [ ] Bullet wording matches the existing concise, declarative style of the surrounding bullets (no emoji, no marketing tone)

**Verify:**

```bash
grep -n "leftmost prompt segment" docs/ux-contract.md
```

Expected: exactly one match, on a line inside the "Prompt Policy" section (line number between 45 and 55).

- [ ] **Step 1: Insert the new bullet**

In `docs/ux-contract.md`, the "Prompt Policy" section currently reads:

```markdown
## Prompt Policy

- The shared prompt baseline is `Starship`
- The prompt should prioritize current context, Git state, and timing over decorative noise
- A fresh NuShell session should drop directly into the normal working flow
- The WezTerm baseline uses a single left prompt
- NuShell's built-in `vi` indicators and right-prompt path are disabled
- On Windows, the WezTerm baseline disables `shell_integration.osc133`
```

Insert a new bullet immediately after `The shared prompt baseline is Starship` so the updated section reads:

```markdown
## Prompt Policy

- The shared prompt baseline is `Starship`
- The leftmost prompt segment is the current OS symbol (`Macos`, `Ubuntu`, `Debian`, `Linux`, or `Windows`)
- The prompt should prioritize current context, Git state, and timing over decorative noise
- A fresh NuShell session should drop directly into the normal working flow
- The WezTerm baseline uses a single left prompt
- NuShell's built-in `vi` indicators and right-prompt path are disabled
- On Windows, the WezTerm baseline disables `shell_integration.osc133`
```

No other bullets change.

- [ ] **Step 2: Verify**

Run:

```bash
grep -n "leftmost prompt segment" docs/ux-contract.md
```

Expected: exactly one match on a line between line numbers 45 and 55.

- [ ] **Step 3: Commit**

```bash
git add docs/ux-contract.md
git commit --only docs/ux-contract.md -m "docs: document OS indicator in UX contract"
```

---

## Self-Review Notes

- Spec coverage check: design doc decisions 1-5 all map to Task 1 or Task 2. Decision 1 (module choice → `$os`), Decision 2 (format position → Task 1 Step 1), Decision 3 (peach color → Task 1 Step 1 & 2), Decision 4 (symbol set → Task 1 Step 2), Decision 5 (file changes → Task 1 + Task 2).
- Non-goals (pwsh, distinguishing WSL Ubuntu from native Ubuntu, other distros) are not added as tasks by design — these are explicit exclusions.
- No tests are added because this repo's `tests/` directory covers NuShell/bash integration only, and the prompt render is verified through the built-in `starship print-config` validator plus a visual smoke check.
