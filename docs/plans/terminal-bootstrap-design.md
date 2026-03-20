# Terminal Bootstrap Design

**Date:** 2026-03-20

## Goal

저장소 루트의 단일 폴더만으로 Windows와 mac에 공통 터미널 UX를 재구성할 수 있는 부트스트랩 자산과 문서를 만든다.

## Constraints

- 설치는 아직 실행하지 않는다.
- 완전 오프라인이 아니라 준오프라인 방식을 사용한다.
- 패키지는 설치 시 인터넷에서 받는다.
- 폰트와 설정 자산은 폴더 내부에 보관한다.
- Windows 메인 사용자를 기준으로 설계한다.
- WSL은 전제로 두지 않는다.

## Decisions

### 1. 구조

공통 자산은 `shared/`에 두고, OS별 진입점은 `windows/`, `mac/`로 나눈다.

이 구조를 선택한 이유:

- 공통 UX 자산을 한 곳에서 관리하기 쉽다.
- mac과 Windows의 설치 흐름 차이를 억지로 숨기지 않아도 된다.
- 장기적으로 스크립트가 늘어나도 유지보수가 쉽다.

### 2. 셸 전략

- Windows 기본 인터랙티브 셸: `MSYS2 UCRT64 bash`
- Windows 보조 셸: `pwsh`
- mac 기본 셸: `zsh`
- WezTerm shell integration 대상: `bash`, `zsh`
- `pwsh`용 shell integration은 현재 범위에서 제외

공통 경험의 기준은 셸 바이너리 자체가 아니라 다음 요소들이다.

- WezTerm
- 키맵
- 폰트
- 색상
- 프롬프트
- `vi`/`vim` -> `nvim`
- `EDITOR`/`VISUAL`

### 3. 폰트 전략

`Monoplex KR Nerd Wide`는 외부 패키지 설치에 맡기지 않고 폴더 내부 자산으로 보관한다.

이유:

- 폰트 이름과 variant를 직접 통제할 수 있다.
- 재설치 시 외부 링크나 패키지 상태에 덜 의존한다.
- mac과 Windows에서 같은 폰트 파일 셋을 기준으로 맞출 수 있다.
- `WezTerm`의 `font_dirs`를 쓰면 OS 전역 폰트 설치 없이도 기준 경로를 고정할 수 있다.

### 4. LazyVim 전략

현재 로컬 Neovim 설정을 그대로 `shared/nvim/`에 임베딩한다.

포함:

- `init.lua`
- `lua/`
- `lazy-lock.json`
- 기타 설정 파일

제외:

- `nvim-data`
- Mason 바이너리
- 세션/캐시/undo/swap

이유:

- 설정은 공통 자산으로 다루기 좋다.
- 실행 파일과 캐시는 OS별 차이가 커서 공유 대상이 아니다.

### 5. 도구 전략

CLI 도구는 역할만 통일한다.

예:

- 검색: `rg`
- 파일 검색: `fd`
- 퍼지 탐색: `fzf`
- 이동: `zoxide`
- 편집기: `nvim`
- Git UI: `lazygit`

세부 설치 방식과 OS별 도구 차이는 허용한다.

Windows 구현에서는 `MSYS2 bash`를 메인 인터랙티브 셸로 쓰되, 대부분의 CLI는 `winget` 또는 `choco`로 네이티브 설치하고 `MSYS2_PATH_TYPE=inherit`로 셸에서 그대로 소비한다.

### 6. Shell Integration 전략

WezTerm의 shell integration은 공통 자산으로 번들한다.

- 원본: WezTerm 공식 `wezterm.sh`
- 저장 위치: `shared/wezterm/wezterm-shell-integration.sh`
- 활성화 대상: `MSYS2 bash`, `zsh`
- 비대상: `pwsh`

이유:

- 새 탭/분할 시 현재 작업 디렉터리 계승 품질이 좋아진다.
- 프롬프트/명령 경계 추적이 개선된다.
- launch menu 같은 추가 UI 설정 없이도 체감 이득이 크다.

## Deliverables

- 폴더 구조
- 설계 문서
- 구현 계획 문서
- 설치 안내 문서
- 공통 UX 규약 문서
- 트러블슈팅 문서
- 공통 설정 파일 초안
- 폰트 자산
- 현재 로컬 LazyVim 스냅샷

## Non-Goals

- 실제 시스템 설치 수행
- WSL 최적화
- AI CLI 도구 설치
- 모든 LSP/formatter 자동 설치 구현

## Open Points

- `Mason` 자동 설치 목록을 공통으로 둘지 추후 결정 필요
