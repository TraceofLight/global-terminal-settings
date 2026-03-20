# Windows Setup Plan

이 문서는 `terminal-bootstrap` 폴더만으로 Windows 환경을 재구성하기 위한 운영 문서다.

설치 스크립트는 작성되어 있고, 아직 실제 실행만 하지 않은 상태를 기준으로 적는다.

## Target State

- 터미널: `WezTerm`
- 기본 인터랙티브 셸: `MSYS2 UCRT64 bash`
- 보조 셸: `pwsh`
- 폰트: `Monoplex KR Nerd Wide`
- 테마: `Dracula`
- 편집기: `Neovim` + 현재 로컬 `LazyVim`

## Implemented Flow

1. `windows/packages.psd1`에 정의된 패키지를 `winget` 우선, `choco` fallback으로 설치한다.
2. 공통 자산을 `%USERPROFILE%\\.config\\terminal-bootstrap` 아래로 스테이징한다.
3. `shared/fonts/MonoplexKRWideNerd`는 OS 전역 폰트 디렉터리가 아니라 스테이징 루트의 `fonts/` 아래에 유지한다.
4. `shared/wezterm/wezterm.lua`를 `%USERPROFILE%\\.wezterm.lua`로 링크하거나 복사한다.
5. `shared/wezterm/wezterm-shell-integration.sh`를 `%USERPROFILE%\\.config\\wezterm\\wezterm-shell-integration.sh`로 링크하거나 복사한다.
6. `shared/starship/starship.toml`를 `%USERPROFILE%\\.config\\starship.toml`로 링크하거나 복사한다.
7. `shared/nvim/`을 `%LOCALAPPDATA%\\nvim`으로 링크하거나 복사한다.
8. `%USERPROFILE%\\.bashrc`, `%USERPROFILE%\\.bash_profile`에 managed block을 추가해 `shared/shell/aliases.sh`를 source 하도록 만든다.
9. PowerShell 프로필에 managed block을 추가해 `shared/shell/aliases.ps1`를 dot-source 하도록 만든다.

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
- `MSYS2`는 셸 환경과 유닉스식 UX를 담당하고, 도구 전체를 `pacman`으로 다시 설치하는 단계는 아직 범위 밖이다.

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
