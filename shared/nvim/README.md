# Neovim Config Snapshot

이 디렉터리는 현재 로컬 Neovim 설정 스냅샷이다.

원본:

- Windows 기준 `%LOCALAPPDATA%\\nvim`

포함:

- `init.lua`
- `lua/`
- `lazy-lock.json`
- 기타 설정 파일

제외:

- `.git`
- `nvim-data`
- Mason 바이너리
- 세션, 캐시, undo, swap

운영 원칙:

- 이 디렉터리를 공통 기준 설정으로 본다.
- 실제 설치 시 각 OS의 Neovim 설정 디렉터리로 링크하거나 복사한다.
