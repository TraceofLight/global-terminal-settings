$env.config = (
  $env.config?
  | default {}
  | merge {
      show_banner: false
      edit_mode: vi
      buffer_editor: "nvim"
      render_right_prompt_on_last_line: false
    }
  | upsert shell_integration { default {} }
  | upsert shell_integration.osc133 false
)

const wezterm_integration = ($nu.default-config-dir | path join "autoload" | path join "wezterm-integration.nu")
const starship_autoload = ($nu.default-config-dir | path join "autoload" | path join "starship.nu")
const zoxide_autoload = ($nu.default-config-dir | path join "autoload" | path join "zoxide.nu")

source $wezterm_integration
source $starship_autoload
source $zoxide_autoload

# Starship does not fully override Nu's vi-mode prompt indicators.
# Keep prompt rendering to a single left-prompt path in WezTerm.
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_MULTILINE_INDICATOR = ""
$env.PROMPT_COMMAND_RIGHT = {|| "" }

alias vi = nvim
alias vim = nvim
alias ls = lsd
alias ll = lsd -l
alias la = lsd -la
alias lt = lsd --tree

if (($nu.os-info.name | str downcase) == "windows") {
  alias btop = btop4win
}
