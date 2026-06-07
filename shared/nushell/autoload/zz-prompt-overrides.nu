# managed by terminal-bootstrap
# terminal-bootstrap prompt guard
export-env {
  let original_prompt_command = $env.PROMPT_COMMAND?

  if ($original_prompt_command | is-empty) {
    $env.PROMPT_COMMAND = {|| "" }
  } else {
    $env.PROMPT_COMMAND = {||
      let last_exit_code = try { ($env.LAST_EXIT_CODE? | default 0 | into int) } catch { 0 }
      if $last_exit_code == 130 {
        ""
      } else {
        try {
          do $original_prompt_command
        } catch {
          ""
        }
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
  $env.PROMPT_COMMAND_RIGHT = ""

  # Drop STARSHIP_SHELL so starship renders [custom.*] modules.
  # starship.nu sets STARSHIP_SHELL="nu" so starship can apply nu-specific
  # output massaging, but a side effect on starship 1.25.x is that
  # [custom] modules are silently omitted from the rendered prompt in
  # that mode (verified: the custom module's bytes are present in
  # `starship prompt` output only when STARSHIP_SHELL is unset/!=nu).
  # We've already replaced PROMPT_INDICATOR_* above (the same things
  # starship's nu integration sets), so dropping STARSHIP_SHELL changes
  # only the missing custom-module behavior — visible prompt is identical
  # otherwise, plus [custom.*] now renders correctly.
  hide-env -i STARSHIP_SHELL
}
