# mac Setup Plan

이 문서는 `terminal-bootstrap` 폴더를 기준으로 mac 환경을 재구성하기 위한 운영 문서다.

설치 스크립트는 작성되어 있고, 아직 실제 실행만 하지 않은 상태를 기준으로 적는다.

## Target State

- 터미널: `WezTerm`
- 기본 셸: `zsh`
- 폰트: `Monoplex KR Nerd Wide`
- 테마: `Catppuccin Mocha`
- 배경 스타일: `window_background_opacity = 0.8` + `macos_window_background_blur = 20`
- 편집기: `Neovim` + 현재 로컬 `LazyVim`

## Implemented Flow

1. Homebrew 존재 여부를 확인한다.
2. `mac/Brewfile` 기준으로 `brew bundle`을 수행한다.
3. 공통 자산을 `~/.config/terminal-bootstrap` 아래로 스테이징한다.
4. `shared/fonts/MonoplexKRWideNerd`는 OS 전역 폰트 디렉터리가 아니라 스테이징 루트의 `fonts/` 아래에 유지한다.
5. `shared/wezterm/wezterm.lua`를 `~/.wezterm.lua`로 링크하거나 복사한다.
6. `shared/wezterm/wezterm-shell-integration.sh`를 `~/.config/wezterm/wezterm-shell-integration.sh`로 링크하거나 복사한다.
7. `shared/starship/starship.toml`를 `~/.config/starship.toml`로 링크하거나 복사한다.
8. `shared/nvim/`을 `~/.config/nvim`으로 링크하거나 복사한다.
9. `.zshrc`에 managed block을 추가해 `shared/shell/aliases.sh`를 source 하도록 만든다.

## Entry Point

```bash
./mac/install.sh --dry-run
```

주요 옵션:

- `--dry-run`: 실제 변경 없이 수행 계획만 출력
- `--sync-mode auto|link|copy`: 자산 동기화 방식 선택
- `--skip-packages`: Homebrew 패키지 설치 생략
- `--skip-configs`: 자산 스테이징과 앱 설정 배치 생략
- `--skip-shell`: `.zshrc` 수정 생략

## Shell Integration Policy

- 대상: `zsh`
- 방식: WezTerm 공식 `wezterm.sh`를 `~/.config/wezterm/wezterm-shell-integration.sh`로 배치하고, `aliases.sh`에서 조건부 source

효과:

- 새 탭/분할 시 현재 작업 디렉터리 전달 개선
- 프롬프트/명령 경계 추적 개선
- WezTerm workspace/mux 사용감 향상

## From The Previous Ghostty-Oriented Setup

유지:

- Homebrew 중심 설치 방식
- CLI 도구 묶음
- `mise`, `zoxide`, `starship`, `lazygit`, `nvim` 중심 워크플로우

제거:

- `Ghostty` 설치 단계
- `Oh My Zsh`, `Zinit`, `SCM Breeze` 강제
- AI CLI 설치 단계

## Package Strategy

- 패키지 목록은 `mac/Brewfile`이 기준이다.
- CLI 도구는 Homebrew가 책임지고, 프롬프트/셸 UX 자산은 `shared/` 스테이징이 책임진다.
- 폰트는 OS 전역 설치가 아니라 `WezTerm`의 `font_dirs`에서 직접 읽는다.

## Why Keep zsh On mac

- mac 기본 셸과 가장 자연스럽게 연결된다.
- Windows와 bash 계열 습관의 접점이 많다.
- 목표는 셸 엔진 자체 통일보다 UX 통일이다.

## Notes

- mac에서는 현재 로컬 `LazyVim` 설정을 그대로 가져오되, 바이너리와 캐시는 새 환경에서 다시 생성한다.
- 필요시 나중에 `Mason` 자동 설치 목록을 별도로 정리할 수 있다.
