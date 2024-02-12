local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.color_scheme = 'iceberg-dark'
config.font = wezterm.font("Monaspace Neon Var")
config.font_size = 16.0
config.window_background_opacity = 0.8
config.keys = {
  {
    key = 'q',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
}

return config
