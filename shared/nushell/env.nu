# GUI-launched WezTerm sessions on macOS do not always inherit Homebrew's PATH.
if (($nu.os-info.name | str downcase) == "macos") {
  let bootstrap_paths = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
  ] | where {|it| $it | path exists }

  $env.PATH = (($bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

if (($nu.os-info.name | str downcase) == "windows") {
  let windows_bootstrap_paths = [
    ($env.APPDATA? | path join "npm")
    ($env.HOME? | path join ".local" | path join "bin")
    ($env.USERPROFILE? | path join ".local" | path join "bin")
  ] | where {|it| ($it != null) and ($it | path exists) }

  $env.PATH = (($windows_bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

if (($nu.os-info.name | str downcase) == "linux") {
  let linux_bootstrap_paths = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
    ($env.HOME? | path join ".local" | path join "bin")
  ] | where {|it| ($it != null) and ($it | path exists) }

  $env.PATH = (($linux_bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
