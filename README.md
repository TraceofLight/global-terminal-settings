# Terminal Bootstrap

Windows와 mac에서 최대한 비슷한 터미널 UX를 재현하기 위한 부트스트랩 저장소다.

이 폴더는 다음을 목표로 한다.

- `WezTerm` 기반 공통 터미널 UX
- `Catppuccin Mocha` 계열 색상과 `Monoplex KR Nerd Wide` 폰트 사용
- 배경은 Windows `Acrylic` + opacity `0.8`, macOS blur `20` 기준
- `MSYS2 UCRT64 bash`(Windows)와 `zsh`(mac)를 쓰되, 체감 UX는 최대한 통일
- `tmux`를 기본 자산으로 포함하되, 바깥 UI는 계속 `WezTerm` 탭/패널을 유지
- 현재 로컬 `LazyVim` 설정을 그대로 자산으로 포함
- 폰트와 설정 파일은 이 폴더 안에 보관하고, 설치 스크립트는 인터넷에서 패키지를 받는 준오프라인 방식

## 폴더 구조

```text
global-terminal-settings/
├─ docs/
│  ├─ plans/
│  ├─ mac-setup.md
│  ├─ troubleshooting.md
│  ├─ ux-contract.md
│  └─ windows-setup.md
├─ mac/
│  └─ install.sh
├─ shared/
│  ├─ fonts/
│  ├─ nvim/
│  ├─ shell/
│  ├─ starship/
│  ├─ tmux/
│  └─ wezterm/
└─ windows/
   └─ install.ps1
```

## 포함 자산

- `shared/fonts/MonoplexKRWideNerd/`
  - 로컬 폰트 원본에서 복사한 폰트 파일
  - 설치 시 `~/.config/terminal-bootstrap/fonts/`로 스테이징
  - `WezTerm`이 `font_dirs`로 직접 로드
- `shared/nvim/`
  - 현재 로컬 Neovim 설정 스냅샷
  - 원본 기준: Windows에서는 `%LOCALAPPDATA%\\nvim`
  - 제외: `.git`, `nvim-data`, 캐시, 세션, Mason 바이너리
- `shared/wezterm/wezterm.lua`
  - 공통 WezTerm 기준 설정
- `shared/wezterm/wezterm-shell-integration.sh`
  - WezTerm 공식 `bash`/`zsh` shell integration 스크립트 번들
- `shared/starship/starship.toml`
  - 공통 프롬프트 기준 설정
- `shared/tmux/.tmux.conf`
  - 공통 tmux 최소 설정
  - `WezTerm` 바깥 UI와 충돌하지 않도록 기본 prefix/동작은 유지
- `shared/shell/aliases.sh`
  - `bash`/`zsh` 공통 alias와 환경변수
- `shared/shell/aliases.ps1`
  - `pwsh` 보조 프로필용 alias와 환경변수

## 범위

포함:

- 터미널
- 셸 UX
- 폰트
- 프롬프트
- CLI 도구 목록
- `LazyVim` 설정 배포 구조

제외:

- `codex`, `claude`, `gemini` 설치
- WSL 기반 워크플로우
- 실제 설치 실행 이력

## 설치 모델

설치 스크립트는 자산을 먼저 `~/.config/terminal-bootstrap/` 아래로 스테이징한 뒤, 앱별 진입점에 링크하거나 복사한다.

- `~/.wezterm.lua`
- `~/.config/wezterm/wezterm-shell-integration.sh`
- `~/.config/starship.toml`
- `~/.tmux.conf`
- Windows: `%LOCALAPPDATA%\\nvim`
- mac: `~/.config/nvim`

폰트는 OS 전역 폰트 설치 대신 `WezTerm`의 `font_dirs`를 사용한다. 따라서 이 부트스트랩 폴더와 스테이징 루트만 유지하면 동일한 폰트 기준을 재현할 수 있다.

Windows에서는 디렉터리 링크를 우선 사용하지만, 파일 단위 설정 타깃은 비관리자 환경에서 copy fallback이 기본 동작일 수 있다.

## 설치 스크립트

- Windows: `windows/install.ps1`
- mac: `mac/install.sh`

둘 다 `dry-run`과 `link/copy` 동기화 모드를 지원한다.

## 시작점

- Windows 기준 계획: [docs/windows-setup.md](docs/windows-setup.md)
- mac 기준 계획: [docs/mac-setup.md](docs/mac-setup.md)
- 공통 UX 규약: [docs/ux-contract.md](docs/ux-contract.md)
- 트러블슈팅: [docs/troubleshooting.md](docs/troubleshooting.md)
- 설계 문서: [docs/plans/terminal-bootstrap-design.md](docs/plans/terminal-bootstrap-design.md)
- 구현 계획: [docs/plans/terminal-bootstrap.md](docs/plans/terminal-bootstrap.md)

## tmux Baseline

- 이 저장소는 `tmux`를 기본 설치/기본 설정 자산으로 포함한다.
- 다만 기본 로컬 멀티플렉서 UI는 여전히 `WezTerm` 탭/패널이다.
- `tmux`는 그 안쪽에서 세션 복귀, 장기 작업, 원격 작업용 레이어로 쓴다.
- Windows/mac 운영 원칙은 각각 [docs/windows-setup.md](docs/windows-setup.md), [docs/mac-setup.md](docs/mac-setup.md)에 정리한다.
