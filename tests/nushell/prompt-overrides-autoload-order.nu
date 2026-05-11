const config = ($nu.default-config-dir | path join "config.nu")
const starship_autoload = ($nu.default-config-dir | path join "autoload" | path join "starship.nu")

source $config

# Interactive NuShell can apply autoload files after config.nu has already run.
# Re-source starship to simulate that load order. Generated starship.nu should
# carry the prompt guard itself, so this must still leave prompt hooks safe.
source $starship_autoload

let left_prompt = (do $env.PROMPT_COMMAND)
if $left_prompt != "" {
  print $"expected PROMPT_COMMAND to fall back to an empty prompt, got ($left_prompt)"
  exit 1
}

let right_prompt = (do $env.PROMPT_COMMAND_RIGHT)
if $right_prompt != "" {
  print $"expected PROMPT_COMMAND_RIGHT to stay disabled, got ($right_prompt)"
  exit 1
}

if $env.PROMPT_MULTILINE_INDICATOR != "" {
  print $"expected PROMPT_MULTILINE_INDICATOR to stay disabled, got ($env.PROMPT_MULTILINE_INDICATOR)"
  exit 1
}

print "PROMPT_OVERRIDES_AUTOLOAD_ORDER_OK"
