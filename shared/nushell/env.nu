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

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
