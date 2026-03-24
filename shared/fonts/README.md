# Fonts

This directory stores font assets that are kept in the repository instead of being re-downloaded during installation.

Currently included:

- `MonoplexKRWideNerd/`

Usage policy:

- Stage the assets into `~/.config/terminal-bootstrap/fonts/` on both Windows and macOS
- Let `WezTerm` load them directly through `font_dirs`

Notes:

- This directory is the installation source asset store
- Do not link or copy these files directly into the system font directories
