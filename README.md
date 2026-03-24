# Terminal Bootstrap

Windows와 mac에서 `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` 기준의 터미널, 셸, 에디터 환경을 재현하기 위한 부트스트랩 저장소다.

## 목표

- `WezTerm` 기반 공통 터미널 UX
- `NuShell` 기반 공통 인터랙티브 셸
- `Catppuccin Mocha`와 `Monoplex KR Nerd Wide` 기준의 공통 외관
- `Starship`, `zoxide`, `fzf`, `rg`, `fd`, `git`, `lazygit` 중심 워크플로우
- 현재 로컬 `LazyVim` 설정을 그대로 자산으로 포함
- Windows/mac 설치 문서를 같은 단계 구조로 유지

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
│  ├─ Brewfile
│  └─ install.sh
├─ shared/
│  ├─ fonts/
│  ├─ nushell/
│  ├─ nvim/
│  ├─ starship/
│  └─ wezterm/
└─ windows/
   ├─ install.ps1
   └─ packages.psd1
```

## 포함 자산

- `shared/fonts/MonoplexKRWideNerd/`
  - 폰트 자산 원본
  - 설치 시 `~/.config/terminal-bootstrap/fonts/`로 스테이징
- `shared/nushell/`
  - 공통 `config.nu`, `env.nu`, `login.nu`
  - WezTerm용 NuShell 연동 레이어
- `shared/nvim/`
  - 현재 `LazyVim` 설정 스냅샷
- `shared/starship/starship.toml`
  - 공통 프롬프트 기준 설정
- `shared/wezterm/wezterm.lua`
  - 공통 WezTerm 기준 설정

## 설치 모델

설치 스크립트는 자산을 먼저 `~/.config/terminal-bootstrap/` 아래로 스테이징한 뒤, 앱별 실제 위치에 링크하거나 복사한다.

- `~/.wezterm.lua`
- `~/.config/starship.toml`
- Windows: NuShell 표준 config dir, 일반적으로 `%APPDATA%\nushell\`
- mac: NuShell 표준 config dir, 일반적으로 `~/Library/Application Support/nushell/`
- Windows: `%LOCALAPPDATA%\nvim`
- mac: `~/.config/nvim`

NuShell용 `Starship`, `zoxide` 초기화 파일은 실제 NuShell 설정 디렉터리의 `autoload/` 아래에 생성하고, `config.nu`가 이를 명시적으로 source 한다.

Windows의 `WezTerm + NuShell` 기준에서는 입력 redraw 안정성을 위해 `shell_integration.osc133`를 비활성화한다. 프롬프트는 `Starship` 단일 왼쪽 프롬프트를 기준으로 두고, NuShell 기본 `vi` indicator와 오른쪽 프롬프트 경로는 사용하지 않는다.

## 공통 설치 단계

Windows와 mac 문서는 같은 8단계를 공유한다.

1. 패키지 관리자 준비
2. 핵심 패키지 설치
3. 공통 자산 스테이징
4. WezTerm 연결
5. NuShell 연결
6. Starship, zoxide, fzf 연결
7. LazyVim 동기화
8. 검증

차이는 실제 명령과 패키지 소스만 둔다.

- Windows: `winget` 우선, `choco` fallback
- mac: `brew`

## 시작점

- Windows 설치 문서: [docs/windows-setup.md](docs/windows-setup.md)
- mac 설치 문서: [docs/mac-setup.md](docs/mac-setup.md)
- 공통 UX 기준: [docs/ux-contract.md](docs/ux-contract.md)
- 트러블슈팅: [docs/troubleshooting.md](docs/troubleshooting.md)
- 설계 문서: [docs/plans/wezterm-nushell-bootstrap-design.md](docs/plans/wezterm-nushell-bootstrap-design.md)
- 구현 계획: [docs/plans/wezterm-nushell-bootstrap.md](docs/plans/wezterm-nushell-bootstrap.md)

## 범위

포함:

- 터미널
- 셸 UX
- 프롬프트
- 탐색/이동 도구
- 폰트
- Neovim 설정 배포 구조

제외:

- 컴파일러와 빌드 툴체인
- 언어별 개발 환경 자동 구성
- WSL 기반 워크플로우
- 과거 셸 구조와의 병행 운영 설명
