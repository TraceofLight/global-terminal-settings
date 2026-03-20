local wezterm = require("wezterm")

local config = wezterm.config_builder()
local bootstrap_dir = wezterm.home_dir .. "/.config/terminal-bootstrap"

local function file_exists(path)
  local ok, _, code = os.rename(path, path)
  return ok or code == 13
end

config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 10000
config.check_for_updates = false
config.default_cwd = wezterm.home_dir
config.default_workspace = "main"
config.font_size = 13.0
config.line_height = 1.05
config.cell_width = 1.0
config.audible_bell = "Disabled"
config.color_scheme = "Dracula (Official)"
config.font_dirs = {
  bootstrap_dir .. "/fonts/MonoplexKRWideNerd",
}

config.font = wezterm.font_with_fallback({
  "Monoplex KR Nerd Wide",
  "MonoplexKRNerdWide",
  "Monoplex KR Nerd",
  "MonoplexKRNerd",
  "JetBrainsMono Nerd Font",
})

config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

config.keys = {
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
  { key = "d", mods = "ALT|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "ALT|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
}

if wezterm.target_triple:find("windows") then
  config.set_environment_variables = {
    CHERE_INVOKING = "1",
    MSYS2_PATH_TYPE = "inherit",
  }
  local system_drive = os.getenv("SystemDrive") or "C:"
  local msys2_shell = system_drive .. "/msys64/msys2_shell.cmd"
  local msys2_bash = system_drive .. "/msys64/usr/bin/bash.exe"
  if file_exists(msys2_shell) then
    config.default_prog = { msys2_shell, "-defterm", "-here", "-no-start", "-ucrt64" }
  elseif file_exists(msys2_bash) then
    config.default_prog = { msys2_bash, "--login", "-i" }
  else
    config.default_prog = { "pwsh.exe", "-NoLogo" }
  end
else
  config.default_prog = { "/bin/zsh", "-l" }
end

return config
