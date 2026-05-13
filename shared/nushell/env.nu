let default_config_home = if ($env.XDG_CONFIG_HOME? | is-not-empty) {
  $env.XDG_CONFIG_HOME
} else if ($env.HOME? | is-not-empty) {
  $env.HOME | path join ".config"
} else if ($env.USERPROFILE? | is-not-empty) {
  $env.USERPROFILE | path join ".config"
} else {
  null
}

if (($env.XDG_CONFIG_HOME? | default "" | is-empty) and ($default_config_home | is-not-empty)) {
  $env.XDG_CONFIG_HOME = $default_config_home
}

let starship_config = if ($env.STARSHIP_CONFIG? | is-not-empty) {
  null
} else if ($env.XDG_CONFIG_HOME? | is-not-empty) {
  $env.XDG_CONFIG_HOME | path join "starship.toml"
} else {
  null
}

if (($starship_config | is-not-empty) and ($starship_config | path exists)) {
  $env.STARSHIP_CONFIG = $starship_config
}

# GUI-launched WezTerm sessions on macOS do not always inherit Homebrew's PATH.
if (($nu.os-info.name | str downcase) == "macos") {
  let bootstrap_paths = [
    ("~/.local/bin" | path expand)
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
  ] | where {|it| $it | path exists }

  $env.PATH = (($bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

if (($nu.os-info.name | str downcase) == "windows") {
  let windows_bootstrap_paths = [
    (if ($env.APPDATA? | is-not-empty) { $env.APPDATA | path join "npm" })
    (if ($env.HOME? | is-not-empty) { $env.HOME | path join ".local" "bin" })
    (if ($env.USERPROFILE? | is-not-empty) { $env.USERPROFILE | path join ".local" "bin" })
    (if ($env.LOCALAPPDATA? | is-not-empty) { $env.LOCALAPPDATA | path join "Microsoft" "WinGet" "Packages" "aquaproj.aqua_Microsoft.Winget.Source_8wekyb3d8bbwe" })
  ] | compact | where {|it| $it | path exists }

  $env.PATH = (($windows_bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

if (($nu.os-info.name | str downcase) == "linux") {
  let linux_bootstrap_paths = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
    (if ($env.HOME? | is-not-empty) { $env.HOME | path join ".local" "bin" })
  ] | compact | where {|it| $it | path exists }

  $env.PATH = (($linux_bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

let aqua_config_home = ($env.XDG_CONFIG_HOME? | default (if ($env.HOME? | is-not-empty) { $env.HOME | path join ".config" } else { null }))
let aqua_global_config = if ($aqua_config_home | is-not-empty) {
  $aqua_config_home | path join "aquaproj-aqua" "aqua.yaml"
} else {
  null
}

if (($env.AQUA_GLOBAL_CONFIG? | default "" | is-empty) and ($aqua_global_config | is-not-empty) and ($aqua_global_config | path exists)) {
  $env.AQUA_GLOBAL_CONFIG = $aqua_global_config
}

let aqua_root = if ($env.AQUA_ROOT_DIR? | is-not-empty) {
  $env.AQUA_ROOT_DIR
} else if (($nu.os-info.name | str downcase) == "windows") {
  if ($env.LOCALAPPDATA? | is-not-empty) {
    $env.LOCALAPPDATA | path join "aquaproj-aqua"
  } else if ($env.HOME? | is-not-empty) {
    $env.HOME | path join ".local" "share" "aquaproj-aqua"
  } else {
    null
  }
} else {
  let aqua_data_home = ($env.XDG_DATA_HOME? | default (if ($env.HOME? | is-not-empty) { $env.HOME | path join ".local" "share" } else { null }))
  if ($aqua_data_home | is-not-empty) {
    $aqua_data_home | path join "aquaproj-aqua"
  } else {
    null
  }
}

let aqua_bin = if ($aqua_root | is-not-empty) {
  $aqua_root | path join "bin"
} else {
  null
}

if (($aqua_bin | is-not-empty) and ($aqua_bin | path exists)) {
  $env.PATH = (([$aqua_bin] | append ($env.PATH? | default [])) | uniq)
}

let mise_shims_candidates = [
  (if ($env.MISE_DATA_DIR? | is-not-empty) { $env.MISE_DATA_DIR | path join "shims" })
  (if ($env.XDG_DATA_HOME? | is-not-empty) { $env.XDG_DATA_HOME | path join "mise" "shims" })
  (if ($env.HOME? | is-not-empty) { $env.HOME | path join ".local" "share" "mise" "shims" })
  (if ($env.LOCALAPPDATA? | is-not-empty) { $env.LOCALAPPDATA | path join "mise" "shims" })
  (if ($env.USERPROFILE? | is-not-empty) { $env.USERPROFILE | path join ".local" "share" "mise" "shims" })
] | compact | where {|it| $it | path exists } | uniq

if ($mise_shims_candidates | is-not-empty) {
  $env.PATH = (($mise_shims_candidates | append ($env.PATH? | default [])) | uniq)
}

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
