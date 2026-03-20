export EDITOR="nvim"
export VISUAL="nvim"

alias vi="nvim"
alias vim="nvim"

shell_name="sh"
if [ -n "${ZSH_VERSION:-}" ]; then
  shell_name="zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
  shell_name="bash"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init "$shell_name")"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$shell_name")"
fi

wezterm_shell_integration="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm-shell-integration.sh"
if [ -f "$wezterm_shell_integration" ]; then
  . "$wezterm_shell_integration"
fi
unset wezterm_shell_integration
