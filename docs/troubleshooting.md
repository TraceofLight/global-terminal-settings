# Troubleshooting

## WezTerm Starts But NuShell Does Not Launch

확인할 것:

- `nu`가 설치되어 있는지
- Windows에서는 `%APPDATA%\nushell\config.nu`가 존재하는지
- mac에서는 `~/Library/Application Support/nushell/config.nu`가 존재하는지
- `~/.wezterm.lua`가 관리 대상 파일을 가리키는지

대응:

- 설치 스크립트를 다시 실행해 NuShell 설정 파일을 재동기화한다.
- `NuShell` 패키지가 누락됐으면 패키지 단계부터 다시 확인한다.
- Windows에서는 `C:\Users\<user>\AppData\Local\Programs\nu\bin\nu.exe`가 실제로 존재하는지 확인한다.

## Nu Command Is Missing In The Current Shell

원인:

- 패키지 설치는 끝났지만 현재 셸 세션 PATH가 아직 갱신되지 않음

대응:

- 새 터미널 세션을 열어 다시 확인한다.
- WezTerm은 일반 설치 경로를 먼저 확인하므로, 현재 셸 PATH가 늦게 갱신돼도 별도 실행은 가능할 수 있다.

## WezTerm Output Moves Up While Typing In NuShell

원인:

- Windows의 WezTerm에서 NuShell 기본 `shell_integration.osc133` prompt marker가 입력 redraw와 충돌할 수 있음

대응:

- [shared/nushell/config.nu](D:/Projects/Github/global-terminal-settings/shared/nushell/config.nu) 기준으로 `shell_integration.osc133 = false` 상태인지 확인한다.
- WezTerm과 NuShell 세션을 완전히 다시 시작해 변경을 반영한다.
- 이 저장소의 NuShell 기준은 `osc133`를 끄고 나머지 terminal integration은 유지하는 쪽이다.

## Starship Or zoxide Does Not Load In NuShell

확인할 것:

- NuShell autoload 디렉터리에 `starship.nu`, `zoxide.nu`가 생성됐는지
- `starship`, `zoxide` 바이너리가 실제 PATH에 있는지
- `config.nu`가 autoload 파일을 명시적으로 source 하고 있는지

대응:

- 설치 스크립트를 다시 실행해 autoload 파일을 재생성한다.
- 패키지 관리자가 해당 CLI를 설치했는지 확인한다.

## Font Does Not Appear In WezTerm

확인할 것:

- 폰트 파일이 `~/.config/terminal-bootstrap/fonts/MonoplexKRWideNerd/` 아래에 있는지
- 설치 후 WezTerm을 완전히 재시작했는지
- `wezterm.lua`의 폰트 이름이 실제 family name과 맞는지

대응:

- `font_with_fallback` 후보 이름을 유지한다.
- 최소한 `Regular`, `Bold`, `Italic` 조합이 스테이징됐는지 확인한다.
- `wezterm ls-fonts`로 실제 인식 상태를 확인한다.

## Symlink Creation Fails

원인:

- Windows 권한 문제
- 플랫폼별 링크 제약

대응:

- 설치 스크립트는 링크 실패 시 복사 모드로 떨어진다.
- 문서에는 링크와 복사 두 경로를 모두 유지한다.

## LazyVim Starts But Tools Are Missing

원인:

- 설정은 복사됐지만 외부 실행 파일이 아직 설치되지 않음
- Neovim 내부 도구가 재설치되지 않음

대응:

- 시스템 도구 설치와 Neovim 내부 도구 설치를 분리해서 본다.
- `shared/nvim`은 설정만 보장하고, 캐시와 도구는 재생성 대상으로 본다.

## Windows Package Install Falls Back To Chocolatey

원인:

- `winget`에 패키지가 없거나 품질이 부족함
- 패키지 정책상 fallback이 허용된 항목임

대응:

- 동일 패키지가 두 관리자에 중복 등록되지 않게 유지한다.
- `choco`는 fallback으로만 사용하고, 기본 경로는 계속 `winget`으로 유지한다.
