const config = ($nu.default-config-dir | path join "config.nu")

source $config

let interrupted_exit_codes = [130, 3221225786, -1073741510]

for exit_code in $interrupted_exit_codes {
  hide-env -i TERMINAL_BOOTSTRAP_PROMPT_WAS_CALLED
  $env.LAST_EXIT_CODE = $exit_code

  let left_prompt = (do $env.PROMPT_COMMAND)
  if $left_prompt != "" {
    print $"expected interrupted PROMPT_COMMAND to return an empty prompt for status ($exit_code), got ($left_prompt)"
    exit 1
  }

  if ($env.TERMINAL_BOOTSTRAP_PROMPT_WAS_CALLED? | default "") != "" {
    print $"expected interrupted PROMPT_COMMAND to skip the original prompt command for status ($exit_code)"
    exit 1
  }
}

let right_prompt_type = ($env.PROMPT_COMMAND_RIGHT | describe)
if $right_prompt_type != "string" {
  print $"expected PROMPT_COMMAND_RIGHT to be a string, got ($right_prompt_type)"
  exit 1
}

if $env.PROMPT_COMMAND_RIGHT != "" {
  print $"expected PROMPT_COMMAND_RIGHT to be empty, got ($env.PROMPT_COMMAND_RIGHT)"
  exit 1
}

print "PROMPT_OVERRIDES_INTERRUPT_STATUS_OK"
