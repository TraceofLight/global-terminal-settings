# Windows Setup

이 문서는 `terminal-bootstrap` 저장소만으로 Windows 환경을 재구성하는 기준 문서다.

## Target State

- 터미널: `WezTerm`
- 기본 인터랙티브 셸: `NuShell`
- 프롬프트: `Starship`
- 탐색/이동: `zoxide`, `fzf`
- 편집기: `Neovim + LazyVim`
- 폰트: `Monoplex KR Nerd Wide`
- 테마: `Catppuccin Mocha`
- 배경 스타일: `window_background_opacity = 0.8` + `win32_system_backdrop = "Acrylic"`

## Entry Point

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

주요 옵션:

- `-DryRun`: 실제 변경 없이 수행 계획만 출력
- `-SyncMode Auto|Link|Copy`: 자산 동기화 방식 선택
- `-SkipPackages`: 패키지 설치 생략
- `-SkipConfigs`: 자산 스테이징과 앱 설정 배치 생략

## Install Flow

### 1. Package Manager Readiness

- 기본 패키지 관리자는 `winget`이다.
- `winget`으로 제공되지 않거나 품질이 부족한 패키지만 `choco` fallback을 사용한다.
- 같은 패키지를 두 관리자가 동시에 소유하지 않게 유지한다.

### 2. Core Packages

기본 패키지 목록은 [windows/packages.psd1](../windows/packages.psd1)가 기준이다.

주요 패키지:

- `WezTerm`
- `NuShell`
- `Neovim`
- `Starship`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- 기타 보조 CLI

### 3. Stage Managed Assets

공통 자산은 `%USERPROFILE%\.config\terminal-bootstrap` 아래로 스테이징한다.

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

다음 파일을 실제 위치에 연결하거나 복사한다.

- `shared/wezterm/wezterm.lua` -> `%USERPROFILE%\.wezterm.lua`
- `shared/starship/starship.toml` -> `%USERPROFILE%\.config\starship.toml`

`WezTerm`의 기본 셸은 `nu -l`이다.

### 5. Wire NuShell

NuShell 설정 파일은 NuShell 표준 config dir 아래에 둔다. 일반적인 위치는 `%APPDATA%\nushell`이다.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload\wezterm-integration.nu`

Windows에서는 NuShell을 별도 프로필 파일이 아니라 WezTerm 진입점으로 사용한다.

Windows의 WezTerm 조합에서는 NuShell `shell_integration.osc133`를 비활성화한다. 기본 prompt marker가 입력 redraw와 충돌할 수 있기 때문이다.

### 6. Starship, zoxide, fzf

설치 스크립트는 NuShell용 autoload 파일을 생성하고, `config.nu`는 이 파일들을 명시적으로 source 한다.

- `starship init nu` -> `%APPDATA%\nushell\autoload\starship.nu`
- `zoxide init nushell` -> `%APPDATA%\nushell\autoload\zoxide.nu`

`fzf`는 외부 CLI로 설치하고, NuShell에서 직접 호출 가능한 상태를 기준으로 둔다.

### 7. Sync LazyVim

`shared/nvim/`을 `%LOCALAPPDATA%\nvim`으로 연결하거나 복사한다.

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

- Windows에서는 비관리자 환경에서 링크가 막힐 수 있다.
- 일부 파일 타깃은 복사가 더 단순하다.

## Notes

- 폰트는 OS 전역 설치 대신 WezTerm의 `font_dirs`로 로드한다.
- Windows 문서의 기준은 `NuShell`이며, 다른 셸 프로필 수정은 범위에 포함하지 않는다.
- `pwsh`는 설치 실행기 역할만 맡고, 일상 인터랙티브 셸 기준은 아니다.
- WezTerm은 Windows에서 `NuShell`의 일반 설치 경로를 먼저 확인하고, 찾지 못하면 `nu.exe`를 이름으로 실행한다.
- 패키지 설치 직후 현재 셸에서 `nu`가 바로 보이지 않으면 새 터미널 세션을 열어 다시 확인한다.
