def __terminal_bootstrap_emit [sequence: string] {
  print -n $sequence
}

def __terminal_bootstrap_emit_cwd [] {
  let esc = (char escape)
  let host = (^hostname | str trim)
  let cwd = ($env.PWD | path expand)
  __terminal_bootstrap_emit $"($esc)]7;file://($host)($cwd)(char bel)"
}

export-env {
  if (($env.TERM_PROGRAM? | default "") == "WezTerm") {
    $env.config = (
      $env.config?
      | default {}
      | upsert hooks { default {} }
      | upsert hooks.pre_prompt { default [] }
      | upsert hooks.env_change { default {} }
      | upsert hooks.env_change.PWD { default [] }
    )

    let prompt_hook = {
      __terminal_bootstrap_wezterm_prompt: true,
      code: {|| __terminal_bootstrap_emit_cwd }
    }

    let pwd_hook = {
      __terminal_bootstrap_wezterm_pwd: true,
      code: {|_, _| __terminal_bootstrap_emit_cwd }
    }

    if not ($env.config.hooks.pre_prompt | any {|hook| (try { $hook.__terminal_bootstrap_wezterm_prompt } catch { false }) }) {
      $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt | append $prompt_hook)
    }

    if not ($env.config.hooks.env_change.PWD | any {|hook| (try { $hook.__terminal_bootstrap_wezterm_pwd } catch { false }) }) {
      $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append $pwd_hook)
    }
  }
}
