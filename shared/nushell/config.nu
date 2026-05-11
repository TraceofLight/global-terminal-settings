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
const carapace_autoload = ($nu.default-config-dir | path join "autoload" | path join "carapace.nu")
const starship_autoload = ($nu.default-config-dir | path join "autoload" | path join "starship.nu")
const zoxide_autoload = ($nu.default-config-dir | path join "autoload" | path join "zoxide.nu")
const openclaude_autoload = ($nu.default-config-dir | path join "autoload" | path join "openclaude.nu")
const openclaude_integration = ($nu.default-config-dir | path join "autoload" | path join "openclaude-integration.nu")
const claude_autoload = ($nu.default-config-dir | path join "autoload" | path join "claude.nu")
const claude_integration = ($nu.default-config-dir | path join "autoload" | path join "claude-integration.nu")
const user_overrides = ($nu.default-config-dir | path join "autoload" | path join "user-overrides.nu")
const prompt_overrides = ($nu.default-config-dir | path join "autoload" | path join "zz-prompt-overrides.nu")

const maybe_wezterm_integration = if ($wezterm_integration | path exists) { $wezterm_integration } else { null }
const maybe_carapace_autoload = if ($carapace_autoload | path exists) { $carapace_autoload } else { null }
const maybe_starship_autoload = if ($starship_autoload | path exists) { $starship_autoload } else { null }
const maybe_zoxide_autoload = if ($zoxide_autoload | path exists) { $zoxide_autoload } else { null }
const maybe_openclaude_autoload = if ($openclaude_autoload | path exists) { $openclaude_autoload } else { null }
const maybe_openclaude_integration = if ($openclaude_integration | path exists) { $openclaude_integration } else { null }
const maybe_claude_autoload = if ($claude_autoload | path exists) { $claude_autoload } else { null }
const maybe_claude_integration = if ($claude_integration | path exists) { $claude_integration } else { null }
const maybe_user_overrides = if ($user_overrides | path exists) { $user_overrides } else { null }
const maybe_prompt_overrides = if ($prompt_overrides | path exists) { $prompt_overrides } else { null }

source $maybe_wezterm_integration
source $maybe_carapace_autoload
source $maybe_starship_autoload
source $maybe_zoxide_autoload
source $maybe_openclaude_autoload
source $maybe_openclaude_integration
source $maybe_claude_autoload
source $maybe_claude_integration
source $maybe_user_overrides
source $maybe_prompt_overrides

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
