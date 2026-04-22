# Prompt OS Indicator Design

> **Status:** Archived historical record. Kept as-is — later revisions did not edit the original plan.
>
> **Diverged from shipped code:**
> - Glyph codepoints were moved from legacy BMP PUA (U+F179, U+F31B, U+F306, U+F17C, U+F17A) to Material Design supplementary PUA (U+F0035, U+F0548, U+F08DA, U+F033D, U+F0372). The legacy range does not render reliably on the current WezTerm + `Monoplex KR Wide Nerd` combination; the supplementary PUA range falls back to the built-in `Symbols Nerd Font Mono`.
> - The `$os` format gained an extra trailing space: `"[ $symbol  ]($style)"`.
> - A matching `$git_branch.symbol` glyph (U+F062C, `md-source-branch`) was added as part of the same rendering fix, outside this plan's original scope.
>
> **Current source of truth:** `shared/starship/starship.toml`, `docs/ux-contract.md` (Prompt Segments section).

**Date:** 2026-04-22

## Goal

Make the Starship prompt visually distinguish the host OS at a glance, so the
same Catppuccin Mocha theme is no longer ambiguous between macOS, native Linux,
WSL Ubuntu, and Windows-native NuShell sessions.

## Constraints

- One shared `shared/starship/starship.toml` must continue to serve all four
  NuShell targets (macOS, native Linux, WSL Ubuntu, Windows-native)
- No new font dependency; only glyphs available in `Monoplex KR Wide Nerd`
- Must not affect pwsh: pwsh does not load Starship in this repo, so a
  Starship-only change is automatically pwsh-neutral
- Must not expand the prompt with decorative noise; the OS indicator counts as
  context (UX contract, Prompt Policy)
- Catppuccin Mocha palette values only; no ad-hoc colors

## Decisions

### 1. Module Choice

Use Starship's built-in `$os` module rather than custom modules with `when`
conditions. Rationale:

- `$os` has no shell-spawn cost per prompt render
- WSL and native Linux both report their Linux distribution through `os_info`,
  which the user accepted as sufficient ("어떤 환경인지만 알면 되는거라서")
- Windows-native NuShell reports `Windows`, covering that case automatically

Custom `when`-gated modules were rejected because they would add a shell spawn
per prompt render without buying a distinction the user asked for.

### 2. Format Position

The OS segment sits at the far left of the powerline, before the existing
`directory` segment. This matches the user's stated request ("경로 맨 앞쪽")
and keeps the read order: *who am I → where am I → what's the repo state →
how long did the last command take → where do I type*.

```
[ OS ] [ directory ] [ git ]  cmd_duration character
```

### 3. Color Segment

The OS segment uses `peach` background with `crust` foreground. Rationale:

- Already present in the Catppuccin Mocha palette block
- Distinct enough from the existing `mauve` (directory) and `blue` (git)
  segments that the three-segment sequence reads as three visually separate
  zones
- Warm-to-cool ordering (`peach → mauve → blue`) matches common powerline
  conventions

### 4. Symbol Set

Only symbols for OSes this repo actually targets are set; Starship's other
defaults are left alone.

| os_info key | Glyph | Environments that hit this key |
|---|---|---|
| `Macos` |  | macOS + nu |
| `Ubuntu` |  | native Ubuntu + nu, WSL Ubuntu + nu |
| `Debian` |  | native Debian + nu |
| `Linux` |  | Fallback for other Linuxes |
| `Windows` |  | Windows-native + nu |

### 5. File Changes

Repository modifications:

- `shared/starship/starship.toml`
  - Prepend the OS segment to `format`
  - Add an `[os]` section with `disabled = false`, style, and format
  - Add an `[os.symbols]` section with the five keys above
- `docs/ux-contract.md`
  - Under "Prompt Policy", note that the leftmost prompt segment is the current
    OS symbol

No other files need changes. `linux/install.sh` and `windows/install.ps1`
already stage the shared `starship.toml` as-is.

## Deliverables

- Updated `shared/starship/starship.toml`
- Updated `docs/ux-contract.md`

## Non-Goals

- Adding an OS indicator to pwsh (pwsh does not load Starship)
- Distinguishing WSL Ubuntu from native Ubuntu (both show ``; accepted)
- Supporting OSes this repo does not target (Arch, Fedora, Alpine, etc.)
- Changing the prompt's right side, git segment colors, or character glyphs
