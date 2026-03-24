def __terminal_bootstrap_emit [sequence: string] {
  print -n $sequence
}

def __terminal_bootstrap_emit_cwd [] {
  let esc = (char --integer 27)
  let host = (^hostname | str trim)
  let cwd = ($env.PWD | path expand)
  let normalized = if (($nu.os-info.name | str downcase) == "windows") {
    ($cwd | str replace -a '\' '/')
  } else {
    $cwd
  }
  let uri_path = if (($nu.os-info.name | str downcase) == "windows") and not ($normalized | str starts-with "/") {
    $"/($normalized)"
  } else {
    $normalized
  }
  __terminal_bootstrap_emit $"($esc)]7;file://($host)($uri_path)(char bel)"
}

export-env {
  if (($env.TERM_PROGRAM? | default "") == "WezTerm") {
    $env.config = (
      $env.config?
      | default {}
      | upsert hooks { default {} }
      | upsert hooks.env_change { default {} }
      | upsert hooks.env_change.PWD { default [] }
    )

    let pwd_hook = {
      __terminal_bootstrap_wezterm_pwd: true,
      code: {|_, _| __terminal_bootstrap_emit_cwd }
    }

    if not ($env.config.hooks.env_change.PWD | any {|hook| (try { $hook.__terminal_bootstrap_wezterm_pwd } catch { false }) }) {
      $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append $pwd_hook)
    }
  }
}
