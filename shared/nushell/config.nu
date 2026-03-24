$env.config = (
  $env.config?
  | default {}
  | merge {
      show_banner: false
      edit_mode: vi
      buffer_editor: "nvim"
    }
)

alias vi = nvim
alias vim = nvim
alias ls = lsd
alias ll = lsd -l
alias la = lsd -la
alias lt = lsd --tree

if (($nu.os-info.name | str downcase) == "windows") {
  alias btop = btop4win
}
