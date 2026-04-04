local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("Hack")
config.font_size = 14
config.cell_width = 1.0
config.line_height = 1.1

-- Theme (TokyoNight Night)
config.color_scheme = "Tokyo Night"

-- Window
config.window_decorations = "TITLE | RESIZE"
config.window_close_confirmation = "NeverPrompt"

-- GPU fallback
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"

-- Keys
config.keys = {
  -- Ctrl+Tab sends CSI-u sequence for tmux window switching
  { key = "Tab", mods = "CTRL", action = wezterm.action.SendString("\x1b[9;5u") },
}

return config
