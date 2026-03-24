# WezTerm NuShell Bootstrap Design

**Date:** 2026-03-25

## Goal

Windows와 mac에서 `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` 기준의 공통 터미널, 셸, 에디터 환경을 재현할 수 있는 부트스트랩 구조를 다시 정의한다.

## Constraints

- 범위는 터미널, 셸, 에디터 환경에 한정한다.
- C/C++ 컴파일러와 빌드 툴체인은 이번 범위에서 제외한다.
- Windows는 네이티브 패키지 설치를 기본으로 삼는다.
- Windows와 mac은 같은 사용자 경험과 같은 문서 구조를 제공해야 한다.
- OS별 설치 구현 차이는 허용하지만, 단계 번호와 의미는 양쪽에서 일치해야 한다.
- 현재 `LazyVim`, `WezTerm`, `Starship` 커스터마이징은 유지되어야 한다.
- 문서는 현재 기준의 정상 경로만 설명하고, 과거 전제나 교체 배경은 적지 않는다.

## Decisions

### 1. Platform Model

공통 표준 스택은 다음으로 고정한다.

- 터미널: `WezTerm`
- 기본 인터랙티브 셸: `NuShell`
- 프롬프트: `Starship`
- 탐색/이동: `fzf`, `zoxide`
- 편집기: `Neovim + LazyVim`

공통 경험의 기준은 셸 바이너리 호환성이 아니라 다음 요소다.

- 동일한 WezTerm 외관
- 동일한 NuShell 진입 흐름
- 동일한 프롬프트 구조
- 동일한 탐색/이동 도구
- 동일한 Neovim 설정

### 2. Package Strategy

Windows와 mac 모두 외부 CLI 도구는 네이티브 패키지로 공급한다.

- Windows 기본 패키지 관리자: `winget`
- Windows 보조 fallback: `choco`
- mac 기본 패키지 관리자: `brew`

Windows에서는 다음 원칙을 따른다.

- 기본 패키지는 `winget`으로 설치한다.
- `winget`에서 제공되지 않거나 품질이 부족한 패키지만 `choco` fallback을 사용한다.
- 같은 패키지를 두 패키지 관리자가 동시에 소유하지 않게 한다.

CLI 도구는 셸 기능이 아니라 설치된 외부 실행 파일 집합으로 취급한다.

### 3. Shell Model

양쪽 OS 모두 `WezTerm`의 기본 셸을 `nu -l`로 설정한다.

NuShell 초기화 책임은 다음 파일로 분리한다.

- `login.nu`: 로그인 세션 시작 시 1회 실행되는 부트스트랩
- `env.nu`: 환경 변수와 경로 정책
- `config.nu`: 인터랙티브 동작, alias, keybinding, hooks

서드파티 초기화는 NuShell 표준 방식에 맞춰 autoload 계층으로 정리한다.

프롬프트 렌더링 기준도 `config.nu`가 명시적으로 정한다.

- `Starship` 왼쪽 프롬프트를 기준으로 사용한다.
- NuShell 기본 `vi` indicator와 multiline indicator는 비활성화한다.
- NuShell 오른쪽 프롬프트 경로는 사용하지 않는다.
- Windows의 WezTerm 조합에서는 `shell_integration.osc133`를 비활성화한다.

### 4. WezTerm Integration Model

`WezTerm`의 외관과 탭/분할 UX는 유지한다. 변경 범위는 셸 진입점과 NuShell 연동 레이어로 제한한다.

NuShell용 WezTerm 연동은 별도 Nu 모듈로 관리한다.

- `env_change.PWD` 기반 작업 디렉터리 변경 추적
- WezTerm용 `OSC 7` 출력
- 입력 redraw를 건드리는 `pre_prompt` 경로는 사용하지 않음

목표는 동일한 구현 방식이 아니라 동일한 체감 UX다.

### 5. Customization Preservation Policy

현재 저장소에 포함된 커스터마이징은 유지 대상이다.

- `shared/nvim/`은 현재 `LazyVim` 스냅샷을 그대로 유지한다.
- `shared/starship/starship.toml`은 프롬프트 모양과 정보 구조를 유지한다.
- `shared/wezterm/wezterm.lua`는 시각 스타일, 폰트, 탭/패널 UX를 유지한다.
- `fzf`, `zoxide`, `rg`, `fd`, `git`, `nvim`의 역할은 유지한다.

허용되는 학습 비용은 NuShell 문법과 명령 체계로 한정한다. 그 외의 사용자 경험 변화는 회귀로 본다.

### 6. File Layout

공통 자산은 `shared/` 아래에 정리한다.

- `shared/wezterm/`
- `shared/nushell/`
- `shared/starship/`
- `shared/nvim/`
- `shared/fonts/`

NuShell 자산은 다음 구조를 기준으로 한다.

- `shared/nushell/config.nu`
- `shared/nushell/env.nu`
- `shared/nushell/login.nu`
- `shared/nushell/autoload/`
- `shared/nushell/wezterm-integration.nu`

스테이징 기준점은 양쪽 OS 모두 `~/.config/terminal-bootstrap/`이다.

### 7. Documentation Model

Windows와 mac 문서는 같은 단계 구조와 같은 번호를 사용한다.

1. 패키지 관리자 준비
2. 핵심 패키지 설치
3. 공통 자산 스테이징
4. WezTerm 연결
5. NuShell 연결
6. Starship, zoxide, fzf 연결
7. LazyVim 동기화
8. 검증

OS별 문서와 설치 스크립트는 위 단계 이름을 공유하고, 실제 명령과 패키지 소스만 다르게 둔다.

### 8. Verification Model

검증은 사용자 체감 기준으로 정의한다.

- WezTerm 실행 시 즉시 NuShell 세션이 열린다.
- Starship 프롬프트가 의도한 형태로 표시된다.
- `zoxide` 이동이 정상 동작한다.
- `fzf` 호출이 가능하다.
- `nvim`이 현재 설정 그대로 열린다.
- 새 탭과 분할이 작업 디렉터리를 자연스럽게 계승한다.

## Deliverables

- 공통 NuShell 자산
- NuShell 기준 WezTerm 설정
- Windows 설치 문서
- mac 설치 문서
- 공통 UX 규약 문서
- 트러블슈팅 문서
- NuShell 중심 설치 스크립트 구조
- 검증 절차 문서

## Non-Goals

- 컴파일러 또는 빌드 툴체인 설치
- 언어별 개발 환경 자동 구성
- 셸 호환성 레이어 유지
- 과거 구조와의 병행 운영 설명
