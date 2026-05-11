# Aqua Core CLI Split Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move non-bootstrap daily CLI tools from OS package baselines into a managed aqua global configuration.

**Architecture:** OS installers keep only the tooling needed to bootstrap and wire the terminal environment: aqua, NuShell, WezTerm, Git, fonts, and managed config deployment. The repository stages `shared/aqua/aqua.yaml` into the live config tree, NuShell exposes `AQUA_GLOBAL_CONFIG` and aqua's root `bin`, and installers run `aqua install -a` opportunistically.

**Tech Stack:** PowerShell installer, Bash installers, NuShell env/config, aqua standard registry.

**Session constraint:** Do not commit. The user explicitly asked to avoid commits in this session. Where this plan would normally commit, review `git status --short` instead.

---

### Task 1: Refresh Design Scope

**Files:**
- Modify: `docs/plans/aqua-core-cli-split-design.md`

**Step 1: Update the design's aqua-owned tool list**

Add `Neovim`, `navi`, and `bottom` to aqua-owned tools.

**Step 2: Verify the document**

Run:

```powershell
Select-String -Path docs\plans\aqua-core-cli-split-design.md -Pattern 'Neovim|navi|bottom'
```

Expected: `Neovim`, `navi`, and `bottom` appear under aqua responsibility.

**Step 3: Review status**

Run:

```powershell
git status --short
```

Expected: modified design file only, plus any already planned files.

### Task 2: Add Managed Aqua Config

**Files:**
- Create: `shared/aqua/aqua.yaml`
- Modify: `docs/plans/README.md`

**Step 1: Create the managed aqua config**

Add:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/aquaproj/aqua/v2.55.0/json-schema/aqua-yaml.json
registries:
  - type: standard
    ref: v4.510.0 # renovate: depName=aquaproj/aqua-registry
packages:
  - name: BurntSushi/ripgrep@15.1.0
  - name: sharkdp/fd@v10.4.2
  - name: sharkdp/bat@v0.26.1
  - name: junegunn/fzf@v0.72.0
  - name: dandavison/delta@0.19.2
  - name: jesseduffield/lazygit@v0.61.1
  - name: bootandy/dust@v1.2.4
  - name: ClementTsang/bottom@0.12.3
  - name: muesli/duf@v0.9.1
  - name: lsd-rs/lsd@v1.2.0
  - name: fastfetch-cli/fastfetch@2.62.1
  - name: ajeetdsouza/zoxide@v0.9.9
  - name: starship/starship@v1.25.1
  - name: carapace-sh/carapace-bin@v1.6.5
  - name: denisidoro/navi@v2.24.0
  - name: neovim/neovim@v0.12.2
```

The package names were checked against aqua's standard registry. The versions were checked from GitHub latest releases on 2026-05-11.

**Step 2: Update the plans README contents**

Add the implementation plan to `docs/plans/README.md`:

```markdown
- [`aqua-core-cli-split.md`](aqua-core-cli-split.md) - implementation plan for the aqua core CLI split.
```

**Step 3: Verify the config is parseable YAML if `yq` is available**

Run:

```powershell
if (Get-Command yq -ErrorAction SilentlyContinue) { yq e '.packages | length' shared\aqua\aqua.yaml }
```

Expected: `16`.

### Task 3: Replace mise With aqua in OS Baselines

**Files:**
- Modify: `windows/packages.psd1`
- Modify: `mac/Brewfile`
- Modify: `linux/Brewfile`

**Step 1: Write a failing package baseline check**

Run before implementation:

```powershell
rg -n 'mise|Name = ''aqua''|brew "aqua"' windows\packages.psd1 mac\Brewfile linux\Brewfile
```

Expected before implementation: `mise` is still present and `aqua` is absent.

**Step 2: Update Windows packages**

In `windows/packages.psd1`, replace the `mise` package block with:

```powershell
@{
    Name = 'aqua'
    DetectCommand = 'aqua'
    WingetId = 'aquaproj.aqua'
    Chocolatey = 'aqua'
}
```

Then remove these aqua-managed packages from the Windows baseline:

- `Neovim`
- `Starship`
- `ripgrep`
- `fd`
- `bat`
- `carapace`
- `zoxide`
- `lazygit`
- `delta`
- `fastfetch`
- `fzf`
- `dust`
- `duf`
- `lsd`
- `navi`

Keep Windows-specific or bootstrap packages:

- `WezTerm`
- `NuShell`
- `Git`
**Step 3: Update macOS and Linux Brewfiles**

Replace `brew "mise"` with `brew "aqua"` and remove aqua-managed CLI tools listed in Step 2. Keep:

- `wezterm`
- `font-symbols-only-nerd-font` on macOS
- `git`
- `nushell`
**Step 4: Verify package baseline state**

Run:

```powershell
rg -n 'mise|ripgrep|brew "rg"|Name = ''ripgrep''' windows\packages.psd1 mac\Brewfile linux\Brewfile
rg -n 'aqua|NuShell|WezTerm|Git' windows\packages.psd1 mac\Brewfile linux\Brewfile
```

Expected: no `mise`; aqua is present in all three baselines; bootstrap packages remain.

### Task 4: Stage and Install Aqua Config

**Files:**
- Modify: `windows/install.ps1`
- Modify: `mac/install.sh`
- Modify: `linux/install.sh`
- Test: `tests/nushell/install-copies-managed-files.sh`

**Step 1: Write a failing file-copy test**

Extend `tests/nushell/install-copies-managed-files.sh` so its test fixture creates `INSTALL_ROOT/aqua/aqua.yaml`, copies it to `CONFIG_ROOT/aqua/aqua.yaml`, and verifies `cmp` succeeds.

Run:

```powershell
bash tests/nushell/install-copies-managed-files.sh
```

Expected before implementation: FAIL because the fixture and installer helper do not yet model aqua config copying.

**Step 2: Stage aqua assets**

Add `Sync-Target`/`sync_target` calls for `shared/aqua`:

- Windows: `Stage-Assets` syncs `shared/aqua` to `%USERPROFILE%\.config\terminal-bootstrap\aqua`
- macOS/Linux: `stage_assets` syncs `shared/aqua` to `$INSTALL_ROOT/aqua`

**Step 3: Wire live aqua config**

Copy staged `aqua/aqua.yaml` to:

- Windows: `%USERPROFILE%\.config\aqua\aqua.yaml`
- macOS/Linux: `${XDG_CONFIG_HOME:-$HOME/.config}/aqua/aqua.yaml`

Use existing `Copy-ManagedFile`/`copy_managed_file` helpers so backups and dry-run behavior match current policy.

**Step 4: Add opportunistic aqua install**

After live aqua config is copied and after NuShell env/config files are in place, add a stage that runs:

```powershell
aqua install -a
```

or:

```bash
aqua install -a
```

Only run when `aqua` is on `PATH`. If it fails, warn and continue. Dry-run should print the planned action only.

**Step 5: Verify**

Run:

```powershell
bash tests/nushell/install-copies-managed-files.sh
pwsh -NoProfile -File .\windows\install.ps1 -DryRun -SkipPackages
bash ./mac/install.sh --dry-run --skip-packages
bash ./linux/install.sh --dry-run --skip-packages --target linux
bash ./linux/install.sh --dry-run --skip-packages --target wsl
```

Expected: tests pass; dry-runs mention staging/copying aqua config and do not fail when aqua-managed tools are absent.

### Task 5: Add NuShell Aqua Environment Wiring

**Files:**
- Modify: `shared/nushell/env.nu`
- Test: `tests/nushell/aqua-env.nu`
- Test: `tests/nushell/aqua-env.sh`

**Step 1: Write failing NuShell env tests**

Create `tests/nushell/aqua-env.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$TEST_ROOT/config/aqua" "$TEST_ROOT/data/aquaproj-aqua/bin"
cp "$REPO_ROOT/shared/nushell/env.nu" "$TEST_ROOT/env.nu"
printf '%s\n' 'registries: []' > "$TEST_ROOT/config/aqua/aqua.yaml"

XDG_CONFIG_HOME="$TEST_ROOT/config" \
XDG_DATA_HOME="$TEST_ROOT/data" \
nu -n "$REPO_ROOT/tests/nushell/aqua-env.nu" "$TEST_ROOT/env.nu" "$TEST_ROOT/config/aqua/aqua.yaml" "$TEST_ROOT/data/aquaproj-aqua/bin"
```

Create `tests/nushell/aqua-env.nu`:

```nu
let env_file = $env.FILE_PWD | path join ($in | default "")
```

Then replace the test body with a NuShell script that:

- sources the env file passed as the first argument
- asserts `$env.AQUA_GLOBAL_CONFIG` equals the second argument
- asserts `$env.PATH | first` equals the third argument

Run:

```powershell
bash tests/nushell/aqua-env.sh
```

Expected before implementation: FAIL because `AQUA_GLOBAL_CONFIG` is not set and aqua `bin` is not prepended.

**Step 2: Implement aqua env setup**

In `shared/nushell/env.nu`, calculate:

- default aqua config: `$env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config") | path join "aqua" "aqua.yaml"`
- default aqua root on Windows: `$env.LOCALAPPDATA | path join "aquaproj-aqua"`
- default aqua root on macOS/Linux: `$env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share") | path join "aquaproj-aqua"`
- aqua bin: `$aqua_root | path join "bin"`

Behavior:

- if `AQUA_ROOT_DIR` already exists in env, use it
- if the aqua config file exists, set `AQUA_GLOBAL_CONFIG`
- if aqua bin exists, prepend it to `PATH`
- leave shell startup clean when files are missing

**Step 3: Verify**

Run:

```powershell
bash tests/nushell/aqua-env.sh
bash tests/nushell/config-missing-autoloads.sh
```

Expected: both pass.

### Task 6: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/windows-setup.md`
- Modify: `docs/mac-setup.md`
- Modify: `docs/linux-setup.md`
- Modify: `docs/plans/aqua-core-cli-split-design.md`

**Step 1: Update setup guides**

Replace `mise` language with aqua language:

- OS package managers install aqua as a bootstrap tool
- aqua manages daily cross-platform CLI tools
- language runtimes, Java included, belong in `autoload/user-overrides.nu`, user aqua config, or project config

**Step 2: Update verification lists**

Explain that `rg`, `fd`, `fzf`, `zoxide`, `starship`, `carapace`, `nvim`, and related CLIs resolve through aqua after install or lazy install.

**Step 3: Verify stale language is gone**

Run:

```powershell
rg -n '\bmise\b|language runtimes themselves are out of scope|Other supporting CLIs' README.md docs windows mac linux shared
```

Expected: no stale `mise` references outside archived plans unless explicitly described as historical.

### Task 7: Final Verification

**Files:**
- All changed files

**Step 1: Run focused tests**

Run:

```powershell
bash tests/nushell/aqua-env.sh
bash tests/nushell/config-missing-autoloads.sh
bash tests/nushell/user-overrides-optional.sh
bash tests/nushell/install-copies-managed-files.sh
```

Expected: all pass.

**Step 2: Run installer dry-runs**

Run:

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun -SkipPackages
bash ./mac/install.sh --dry-run --skip-packages
bash ./linux/install.sh --dry-run --skip-packages --target linux
bash ./linux/install.sh --dry-run --skip-packages --target wsl
```

Expected: all dry-runs complete without requiring network installs.

**Step 3: Review diff**

Run:

```powershell
git diff -- README.md docs windows mac linux shared tests
git status --short
```

Expected: only aqua split files are changed. No commit is created.
