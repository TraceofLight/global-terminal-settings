# Windows Setup Plan

이 문서는 `terminal-bootstrap` 폴더만으로 Windows 환경을 재구성하기 위한 운영 문서다.

설치 스크립트는 작성되어 있고, 아직 실제 실행만 하지 않은 상태를 기준으로 적는다.

## Target State

- 터미널: `WezTerm`
- 기본 인터랙티브 셸: `MSYS2 UCRT64 bash`
- 보조 셸: `pwsh`
- 기본 내부 세션 도구: `tmux`
- 폰트 자산: `Monoplex KR Nerd Wide`
- WezTerm font family: `Monoplex KR Nerd`
- 테마: `Catppuccin Mocha`
- 배경 스타일: `window_background_opacity = 0.8` + `win32_system_backdrop = "Acrylic"`
- 편집기: `Neovim` + 현재 로컬 `LazyVim`

## Implemented Flow

1. `windows/packages.psd1`에 정의된 패키지를 `winget` 우선, `choco` fallback으로 설치한다.
2. `MSYS2`가 준비된 뒤 `pacman -S --needed tmux`로 `tmux`를 설치한다.
3. 공통 자산을 `%USERPROFILE%\\.config\\terminal-bootstrap` 아래로 스테이징한다.
4. `shared/fonts/MonoplexKRWideNerd`는 OS 전역 폰트 디렉터리가 아니라 스테이징 루트의 `fonts/` 아래에 유지한다.
5. `shared/wezterm/wezterm.lua`를 `%USERPROFILE%\\.wezterm.lua`로 링크하거나 복사한다.
6. `shared/wezterm/wezterm-shell-integration.sh`를 `%USERPROFILE%\\.config\\wezterm\\wezterm-shell-integration.sh`로 링크하거나 복사한다.
7. `shared/starship/starship.toml`를 `%USERPROFILE%\\.config\\starship.toml`로 링크하거나 복사한다.
8. `shared/tmux/.tmux.conf`를 `%USERPROFILE%\\.tmux.conf`로 링크하거나 복사한다.
9. `shared/nvim/`을 `%LOCALAPPDATA%\\nvim`으로 링크하거나 복사한다.
10. `%USERPROFILE%\\.bashrc`, `%USERPROFILE%\\.bash_profile`에 managed block을 추가해 `shared/shell/aliases.sh`를 source 하도록 만든다.
11. PowerShell 프로필에 managed block을 추가해 `shared/shell/aliases.ps1`를 dot-source 하도록 만든다.

실제 기본 원칙:

- WezTerm이 `HOME=%USERPROFILE%`를 `MSYS2 bash`에 넘긴다.
- 따라서 `.bashrc`, `.bash_profile`, `.config/terminal-bootstrap`의 기준점은 Windows 홈 하나로 고정된다.

## Entry Point

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

주요 옵션:

- `-DryRun`: 실제 변경 없이 수행 계획만 출력
- `-SyncMode Auto|Link|Copy`: 자산 동기화 방식 선택
- `-SkipPackages`: 패키지 설치 생략
- `-SkipConfigs`: 자산 스테이징과 앱 설정 배치 생략
- `-SkipShellProfiles`: `.bashrc`, `.bash_profile`, PowerShell 프로필 수정 생략

## Package Strategy

- 기본 방향은 `MSYS2 bash`를 셸로 쓰되, 대부분의 CLI는 Windows 네이티브 패키지로 설치한다.
- `wezterm.lua`가 `MSYS2_PATH_TYPE=inherit`를 설정하므로, 네이티브 설치된 도구가 `MSYS2 bash`에서 그대로 보인다.
- `tmux`는 예외적으로 `MSYS2` 내부 패키지로 기본 설치한다.
- `winget`이 있는 패키지는 `winget`을 우선 사용한다.
- `choco`는 `winget`에 없는 패키지에만 fallback으로 사용한다.
- 비관리자 환경에서 `choco`가 필요한 optional 패키지는 전체 설치를 멈추지 않고 warning 후 건너뛴다.
- `btop4win`은 Windows 패키지명이지만 셸 UX에서는 `btop` alias로 노출한다.

## Shell Integration Policy

- 대상: `MSYS2 bash`
- 비대상: `pwsh`
- 방식: WezTerm 공식 `wezterm.sh`를 `~/.config/wezterm/wezterm-shell-integration.sh`로 배치하고, `aliases.sh`에서 조건부 source

효과:

- 새 탭/분할 시 현재 작업 디렉터리 계승 안정화
- 명령 경계 추적 개선
- 별도 launch menu 설정 없이 mux 체감 개선

## Sync Policy

- 기본값: 링크
- fallback: 복사

권장 이유:

- 저장소 루트를 기준점으로 유지할 수 있다.
- 자산 수정이 즉시 반영된다.

복사를 허용하는 이유:

- 권한 문제로 심볼릭 링크가 막힐 수 있다.
- 일부 환경에서는 복사가 더 단순하다.

`Auto` 모드는 링크를 먼저 시도하고 실패하면 복사로 떨어진다.

추가 원칙:

- 스테이징 디렉터리(`~/.config/terminal-bootstrap`) 아래 디렉터리는 링크를 우선한다.
- `.wezterm.lua`, `starship.toml`, `wezterm-shell-integration.sh` 같은 파일 타깃은 비관리자 Windows에서 copy fallback이 정상 동작이다.
- 따라서 설정을 수정한 뒤 파일 타깃 반영이 필요하면 설치 스크립트를 다시 실행해 재동기화한다.

## Tool Ownership

- 시스템 설치기: `winget`, `choco`, 공식 설치 파일 중 하나
- 셸 사용자land: `MSYS2 UCRT64`
- 편집기 설정: `shared/nvim`
- 프롬프트: `shared/starship`
- 패키지 매니페스트: `windows/packages.psd1`

## Things To Avoid

- WSL을 기본 워크플로우로 엮기
- `MSYS2` 전체를 전역 PATH 표준으로 강제하기
- `nvim-data`를 공유 자산으로 취급하기
- `pwsh`를 완전히 제거하기
- `pwsh`에 WezTerm shell integration까지 억지로 맞추기

## Notes

- Windows에서는 `Mason`이 외부 도구 설치에 `pwsh` 또는 `powershell`을 요구할 수 있다.
- 따라서 일상 셸은 `bash`여도 `pwsh`는 보조 경로로 남겨두는 편이 안전하다.
- 폰트는 OS 전역 설치가 아니라 `WezTerm`의 `font_dirs`에서 직접 읽는다.
- PowerShell 공유 alias는 세션 시작 시 Machine/User PATH를 다시 합쳐서 `starship`, `zoxide` 같은 사용자 설치 바이너리를 바로 인식하게 한다.

## tmux On Windows

현재 운영 원칙:

- 기본 로컬 UI는 `WezTerm` 탭/패널을 유지한다.
- `tmux`는 기본 설치/기본 세팅 대상이다.
- 즉, `WezTerm` 시작 시 `tmux`를 자동 attach 하지는 않는다.
- 로컬에서는 필요할 때만 `tmux`를 실행하고, 장기 작업이나 원격 서버 세션 유지가 필요할 때 활용한다.

설치 위치:

- `WezTerm`이 Windows에서 기본 셸로 `MSYS2 UCRT64 bash`를 사용하므로, `tmux`도 `MSYS2` 쪽에 설치한다.

권장 최소 설정:

```tmux
set -g mouse on
set -g history-limit 100000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
setw -g mode-keys vi
set -g default-terminal "tmux-256color"
set -as terminal-features ",tmux-256color:RGB"
set -as terminal-features ",xterm-256color:RGB"
set -as terminal-features ",wezterm:RGB"
bind r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"
```

운영 방식:

- 시작: `tmux new -As main`
- 세션 목록: `tmux ls`
- 다시 붙기: `tmux attach -t main`
- detach: `Ctrl+b` 다음 `d`
- 새 창: `Ctrl+b` 다음 `c`
- 창 이동: `Ctrl+b` 다음 `1~9`, `n`, `p`
- 좌우 분할: `Ctrl+b` 다음 `%`
- 위아래 분할: `Ctrl+b` 다음 `"`

주의:

- `WezTerm` 탭과 `tmux` 창은 별개다.
- `Ctrl+Shift+T`는 `WezTerm` 탭을 추가하는 키이고, 새 `tmux` 세션을 자동 생성하지는 않는다.
- 따라서 로컬에서는 바깥 레이어를 `WezTerm`, 내부 세션 레이어를 `tmux`로 분리해서 생각하는 편이 덜 헷갈린다.
