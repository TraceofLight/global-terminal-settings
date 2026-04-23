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
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.8
config.text_background_opacity = 1.0
config.font_dirs = {
  bootstrap_dir .. "/fonts/MonoplexKRWideNerd",
}

config.font = wezterm.font_with_fallback({
  "Monoplex KR Wide Nerd",
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
})

-- Suppress missing-glyph warnings. Some processes emit stray codepoints
-- (e.g. unassigned U+05F7) that no bundled or system font can render, and
-- the resulting warnings are noise rather than an actionable signal. Flip
-- back to true temporarily if a real glyph (Korean, Nerd Font icon, etc.)
-- starts rendering as a placeholder and we need to diagnose it.
config.warn_about_missing_glyphs = false

config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}

config.keys = {
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
  { key = "d", mods = "ALT|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "ALT|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
}

if wezterm.target_triple:find("windows") then
  local windows_home = wezterm.home_dir:gsub("\\", "/")
  local nu_candidates = {
    os.getenv("LOCALAPPDATA") and (os.getenv("LOCALAPPDATA"):gsub("\\", "/") .. "/Programs/nu/bin/nu.exe") or nil,
    os.getenv("ProgramFiles") and (os.getenv("ProgramFiles"):gsub("\\", "/") .. "/nu/bin/nu.exe") or nil,
  }
  config.win32_system_backdrop = "Acrylic"
  config.set_environment_variables = {
    HOME = windows_home,
    XDG_CONFIG_HOME = windows_home .. "/.config",
  }
  for _, nu_path in ipairs(nu_candidates) do
    if nu_path and file_exists(nu_path) then
      config.default_prog = { nu_path, "-l" }
      break
    end
  end
  if not config.default_prog then
    config.default_prog = { "nu.exe", "-l" }
  end
  config.wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      default_cwd = "~",
      -- `wsl.exe -- cmd` runs cmd directly without a login shell, so
      -- PATH does not include Linuxbrew's bin. Invoke nu by absolute
      -- path to avoid a "command not found" on tab spawn.
      default_prog = { "/home/linuxbrew/.linuxbrew/bin/nu", "-l" },
    },
  }
  config.launch_menu = {
    { label = "WSL Ubuntu (nu)", domain = { DomainName = "WSL:Ubuntu" } },
  }
else
  if wezterm.target_triple:find("darwin") then
    config.macos_window_background_blur = 20
    config.set_environment_variables = {
      XDG_CONFIG_HOME = wezterm.home_dir .. "/.config",
    }
  end
  if file_exists("/opt/homebrew/bin/nu") then
    config.default_prog = { "/opt/homebrew/bin/nu", "-l" }
  elseif file_exists("/usr/local/bin/nu") then
    config.default_prog = { "/usr/local/bin/nu", "-l" }
  else
    config.default_prog = { "nu", "-l" }
  end
end

return config
