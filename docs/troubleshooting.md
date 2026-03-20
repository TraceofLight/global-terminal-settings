# Troubleshooting

## Font Does Not Appear In WezTerm

확인할 것:

- 폰트 파일이 `~/.config/terminal-bootstrap/fonts/MonoplexKRWideNerd/` 아래에 있는지
- 설치 후 터미널을 완전히 재시작했는지
- `wezterm.lua`의 폰트 이름이 실제 family name과 맞는지
- `~/.wezterm.lua`가 스테이징된 `wezterm.lua`를 가리키는지

대응:

- `font_with_fallback`에 후보 이름을 여러 개 둔다.
- 최소한 `Regular`, `Bold`, `Italic` 조합이 스테이징됐는지 확인한다.
- `wezterm ls-fonts`로 실제 인식 상태를 확인한다.

## Symlink Creation Fails

원인:

- Windows 권한 문제
- 개발자 모드 미활성화

대응:

- 설치 스크립트는 링크 실패 시 복사 모드로 떨어진다.
- 문서에 링크와 복사 두 경로를 모두 유지한다.

## MSYS2 And Windows Tool Conflicts

원인:

- `find`, `sort`, `tar`, `ssh`, `git` 우선순위 충돌
- 경로 변환 자동 처리로 인한 인자 깨짐

대응:

- 전역 PATH 오염을 최소화한다.
- WezTerm 프로필 기준으로 `MSYS2`를 실행한다.
- 네이티브 Windows 관리 작업은 `pwsh`에서 처리한다.

## LazyVim Starts But Tools Are Missing

원인:

- 설정은 복사됐지만 외부 실행 파일이 아직 설치되지 않음
- `Mason` 패키지가 재설치되지 않음

대응:

- 시스템 도구 설치와 Neovim 내부 도구 설치를 분리해서 본다.
- `shared/nvim`은 설정만 보장하고, 캐시와 도구는 재생성 대상으로 본다.

## Clipboard Or Shell Integration Differs By OS

원인:

- OS별 기본 셸 차이
- 터미널과 셸의 초기화 파일 차이
- `wezterm-shell-integration.sh` 배치 누락

대응:

- 공통 alias는 `shared/shell/`에 유지한다.
- `~/.config/wezterm/wezterm-shell-integration.sh` 존재 여부를 먼저 확인한다.
- OS별 예외는 설치 스크립트에서만 얇게 처리한다.
