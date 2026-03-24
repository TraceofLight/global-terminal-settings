# mac Setup

이 문서는 `terminal-bootstrap` 저장소만으로 mac 환경을 재구성하는 기준 문서다.

## Target State

- 터미널: `WezTerm`
- 기본 인터랙티브 셸: `NuShell`
- 프롬프트: `Starship`
- 탐색/이동: `zoxide`, `fzf`
- 편집기: `Neovim + LazyVim`
- 폰트: `Monoplex KR Nerd Wide`
- 테마: `Catppuccin Mocha`
- 배경 스타일: `window_background_opacity = 0.8` + `macos_window_background_blur = 20`

## Entry Point

```bash
./mac/install.sh --dry-run
```

주요 옵션:

- `--dry-run`: 실제 변경 없이 수행 계획만 출력
- `--sync-mode auto|link|copy`: 자산 동기화 방식 선택
- `--skip-packages`: Homebrew 패키지 설치 생략
- `--skip-configs`: 자산 스테이징과 앱 설정 배치 생략

## Install Flow

### 1. Package Manager Readiness

- 기본 패키지 관리자는 `brew`다.
- 설치 스크립트는 Homebrew가 없으면 먼저 준비한다.

### 2. Core Packages

기본 패키지 목록은 [mac/Brewfile](../mac/Brewfile)가 기준이다.

주요 패키지:

- `wezterm`
- `nushell`
- `neovim`
- `starship`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- 기타 보조 CLI

### 3. Stage Managed Assets

공통 자산은 `~/.config/terminal-bootstrap` 아래로 스테이징한다.

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

다음 파일을 실제 위치에 연결하거나 복사한다.

- `shared/wezterm/wezterm.lua` -> `~/.wezterm.lua`
- `shared/starship/starship.toml` -> `~/.config/starship.toml`

`WezTerm`의 기본 셸은 `nu -l`이다.

### 5. Wire NuShell

NuShell 설정 파일은 표준 위치인 `~/Library/Application Support/nushell` 아래에 둔다.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`

### 6. Starship, zoxide, fzf

설치 스크립트는 NuShell용 autoload 파일을 생성한다.

- `starship init nu` -> `~/Library/Application Support/nushell/autoload/starship.nu`
- `zoxide init nushell` -> `~/Library/Application Support/nushell/autoload/zoxide.nu`

`fzf`는 외부 CLI로 설치하고, NuShell에서 직접 호출 가능한 상태를 기준으로 둔다.

### 7. Sync LazyVim

`shared/nvim/`을 `~/.config/nvim`으로 연결하거나 복사한다.

이 저장소는 설정만 책임지고, 캐시와 외부 도구는 새 환경에서 다시 생성한다.

### 8. Verify

최소 검증 기준:

- WezTerm이 바로 열리고 NuShell이 시작된다.
- Starship 프롬프트가 표시된다.
- `zoxide`, `fzf`, `rg`, `fd`, `git`, `nvim`이 실행된다.
- 새 탭/분할에서 작업 흐름이 자연스럽게 이어진다.

## Sync Policy

- 기본값: 링크
- fallback: 복사

권장 이유:

- 저장소와 스테이징 디렉터리를 source of truth로 유지할 수 있다.
- 자산 수정이 즉시 반영된다.

복사를 허용하는 이유:

- 일부 파일 타깃은 복사가 더 단순하다.
- 환경별 권한 차이를 덜 신경 써도 된다.

## Notes

- 폰트는 OS 전역 설치 대신 WezTerm의 `font_dirs`로 로드한다.
- mac 문서의 기준도 `NuShell`이며, 다른 셸 프로필 수정은 범위에 포함하지 않는다.
- Homebrew는 설치 실행기이자 패키지 공급원이고, 일상 인터랙티브 셸 기준은 아니다.
