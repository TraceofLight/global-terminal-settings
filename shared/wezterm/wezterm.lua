local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
local bootstrap_dir = wezterm.home_dir .. "/.config/terminal-bootstrap"
local function file_exists(path)
  local ok, _, code = os.rename(path, path)
  return ok or code == 13
end

local function basename(path)
  return (path:gsub("\\", "/"):match("([^/]+)$") or path):lower()
end

local function pane_title(pane)
  local ok, title = pcall(function()
    return pane:get_title()
  end)
  if ok and title then
    return title
  end
  return ""
end

local function foreground_process(pane)
  local ok, name = pcall(function()
    return pane:get_foreground_process_name()
  end)
  if ok and name then
    return basename(name)
  end
  return ""
end

local function is_agent_pane(pane)
  local process = foreground_process(pane)
  if process == "codex.exe" or process == "codex" or process == "claude.exe" or process == "claude" then
    return true
  end

  local title = pane_title(pane):lower()
  if title:find("codex", 1, true) or title:find("claude", 1, true) then
    return true
  end

  -- Agent CLIs (Codex, Claude Code) render an asterisk marker (U+2733) in the
  -- pane title while busy. Trust it only alongside a generic host process so
  -- ordinary shell/editor panes still receive a literal Ctrl+V.
  local has_agent_marker = pane_title(pane):find("\226\156\179", 1, true) ~= nil
  return has_agent_marker and (process == "node.exe" or process == "node" or process == "cmd.exe" or process == "")
end

local function save_clipboard_image_path()
  if not wezterm.target_triple:find("windows") then
    return nil
  end

  local script_path = bootstrap_dir .. "/wezterm/save-clipboard-image.ps1"
  if not file_exists(script_path) then
    wezterm.log_warn("clipboard image helper missing: " .. script_path)
    return nil
  end

  local success, stdout, stderr = wezterm.run_child_process({
    "powershell.exe",
    "-NoProfile",
    "-Sta",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    script_path,
  })

  stdout = stdout or ""
  local path = stdout:match("IMAGE_PATH=([^\r\n]+)")
  if success and path and path ~= "" then
    return path
  end

  if not stdout:find("NO_IMAGE", 1, true) and stderr and stderr ~= "" then
    wezterm.log_warn("clipboard image helper failed: " .. stderr)
  end
  return nil
end

local function agent_clipboard_paste(window, pane)
  if not is_agent_pane(pane) then
    window:perform_action(act.SendKey({ key = "v", mods = "CTRL" }), pane)
    return
  end

  local image_path = save_clipboard_image_path()
  if image_path then
    pane:send_paste(image_path)
    return
  end

  window:perform_action(act.PasteFrom("Clipboard"), pane)
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
config.font_size = 15.0
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
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL", action = wezterm.action_callback(agent_clipboard_paste) },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "d", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
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
