# UX Contract

이 문서는 Windows와 mac에서 반드시 같아야 하는 사용자 경험과, 달라도 되는 영역을 구분한다.

## Must Match

- 터미널 프로그램은 `WezTerm`
- 기본 색상 방향은 `Dracula`
- 기본 폰트는 `Monoplex KR Nerd Wide`
- `bash`/`zsh`는 WezTerm shell integration을 활성화
- `vi`, `vim`은 `nvim`으로 연결
- `EDITOR`와 `VISUAL`은 `nvim`
- 공통 탐색 도구는 `rg`, `fd`, `fzf`, `zoxide`
- Git TUI는 `lazygit`
- Neovim UX는 현재 `LazyVim` 스냅샷 기준

## May Differ

- Windows의 기본 인터랙티브 셸은 `MSYS2 UCRT64 bash`
- mac의 기본 셸은 `zsh`
- 외부 도구 설치 방식
- OS별 LSP/formatter 실제 바이너리 경로
- 클립보드 세부 구현
- `pwsh`는 shell integration 비대상

## Command Policy

- 일상 파일 탐색: `fd`
- 일상 텍스트 검색: `rg`
- 디렉터리 이동: `zoxide`
- 에디터 호출: `nvim`
- 짧은 편집 호출: `vi`, `vim`

## Prompt Policy

- 장기적으로는 `starship`을 공통 기준으로 삼는다.
- Windows 기존 `oh-my-posh`는 마이그레이션 대상이다.
- 프롬프트는 과도한 장식보다 현재 작업 맥락, Git 상태, 시간 정보를 우선한다.

## Font Policy

- 폰트는 설치 스크립트가 외부에서 받지 않는다.
- `shared/fonts/` 안의 파일을 설치 원본으로 사용한다.
- 설치 시 `~/.config/terminal-bootstrap/fonts/`로 스테이징한다.
- `WezTerm`이 `font_dirs`로 직접 읽는다.
- 기본 대상은 `MonoplexKRWideNerd-Regular.ttf` 계열이다.

## LazyVim Policy

- 기준 자산은 `shared/nvim`
- `nvim-data`는 공유 대상이 아니다
- 캐시와 패키지 바이너리는 각 OS에서 다시 생성한다
