# Fonts

이 디렉터리는 설치 시 외부에서 다시 받지 않을 폰트 자산을 보관한다.

현재 포함:

- `MonoplexKRWideNerd/`

사용 원칙:

- Windows/mac 공통으로 `~/.config/terminal-bootstrap/fonts/`에 스테이징
- `WezTerm`이 `font_dirs`를 통해 직접 로드

주의:

- 이 폴더는 설치 원본 저장소다.
- 시스템 폰트 영역에 직접 링크하거나 복사하지 않는다.
