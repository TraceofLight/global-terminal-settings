# managed by terminal-bootstrap
# terminal-bootstrap prompt guard
export-env {
  let original_prompt_command = $env.PROMPT_COMMAND?

  if ($original_prompt_command | is-empty) {
    $env.PROMPT_COMMAND = {|| "" }
  } else {
    $env.PROMPT_COMMAND = {||
      try {
        do $original_prompt_command
      } catch {
        ""
      }
    }
  }

  $env.config = (
    $env.config?
    | default {}
    | merge {
        render_right_prompt_on_last_line: false
      }
  )

  $env.PROMPT_INDICATOR = ""
  $env.PROMPT_INDICATOR_VI_INSERT = ""
  $env.PROMPT_INDICATOR_VI_NORMAL = ""
  $env.PROMPT_MULTILINE_INDICATOR = ""
  $env.PROMPT_COMMAND_RIGHT = {|| "" }
}
