# UX Contract

이 문서는 Windows와 mac에서 반드시 같아야 하는 사용자 경험과, OS별로 달라도 되는 영역을 구분한다.

## Must Match

- 터미널 프로그램은 `WezTerm`
- 기본 인터랙티브 셸은 `NuShell`
- 기본 프롬프트는 `Starship`
- 기본 색상 방향은 `Catppuccin Mocha`
- 배경 스타일은 `window_background_opacity = 0.8` 기준
- Windows는 `Acrylic`, mac은 blur `20`
- 기본 폰트는 `Monoplex KR Nerd Wide`
- `vi`, `vim`은 `nvim`
- `EDITOR`와 `VISUAL`은 `nvim`
- 공통 탐색 도구는 `rg`, `fd`, `fzf`, `zoxide`
- Git TUI는 `lazygit`
- Neovim UX는 현재 `LazyVim` 스냅샷 기준
- 설치 문서의 단계 번호와 의미는 동일해야 한다

## May Differ

- 패키지 관리자
- 외부 도구 설치 방식
- OS별 바이너리 실제 경로
- 클립보드 세부 구현
- NuShell 설정 파일의 실제 표준 위치

## Command Policy

- 기본 목록 조회: `ls` -> `lsd`
- 상세 목록 조회: `ll`, `la`
- 트리 목록 조회: `lt`
- 일상 파일 탐색: `fd`
- 일상 텍스트 검색: `rg`
- 디렉터리 이동: `zoxide`
- 에디터 호출: `nvim`
- 짧은 편집 호출: `vi`, `vim`

## Prompt Policy

- 공통 기준은 `Starship`
- 프롬프트는 과도한 장식보다 현재 작업 맥락, Git 상태, 시간 정보를 우선한다
- NuShell 진입 직후 곧바로 현재 작업 흐름에 들어갈 수 있어야 한다

## Font Policy

- 폰트는 설치 스크립트가 외부에서 받지 않는다
- `shared/fonts/` 안의 파일을 설치 원본으로 사용한다
- 설치 시 `~/.config/terminal-bootstrap/fonts/`로 스테이징한다
- `WezTerm`이 `font_dirs`로 직접 읽는다

## Editor Policy

- 기준 자산은 `shared/nvim`
- `nvim-data`는 공유 대상이 아니다
- 캐시와 패키지 바이너리는 각 OS에서 다시 생성한다
