# Plans

Current design docs and implementation plans for active or proposed work.

Use `archive/` for historical plans that have already been executed. Archived files keep their original body untouched, with a short status header when current behavior has diverged.

## Naming

- Use descriptive, date-free filenames.
- Good: `aqua-core-cli-split-design.md`
- Avoid: `2026-05-11-aqua-core-cli-split-design.md`
- It is fine to record the design date inside the document body, but do not put the design date in the filename.

## Contents

- [`aqua-core-cli-split-design.md`](aqua-core-cli-split-design.md) - design for moving cross-platform daily CLI tooling to aqua while keeping OS installers focused on bootstrap responsibilities.
- [`aqua-core-cli-split.md`](aqua-core-cli-split.md) - implementation plan for the aqua core CLI split.
- [`windows-nvim-cache-design.md`](windows-nvim-cache-design.md) - design for avoiding Windows Neovim Lua cache path length failures with aqua-managed Neovim.
- [`windows-nvim-cache.md`](windows-nvim-cache.md) - implementation plan for the Windows Neovim aqua root and cache path defaults.
- [`archive/`](archive/) - historical plans and designs.
