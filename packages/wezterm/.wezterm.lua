local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- see https://leaysgur.github.io/wezterm-colorscheme/
config.color_scheme = 'Twilight (light) (terminal.sexy)'

config.font = wezterm.font_with_fallback {
  { family = "Moralerspace Argon", assume_emoji_presentation = true }
}

config.font_size = 16.0
config.scrollback_lines = 10000
config.keys = {
  {
    key = '|',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  { 
    key="Enter",
    mods="SHIFT",
    action=wezterm.action{SendString="\x1b\r"}
  },
  {
    key = '\\',
    mods = 'CMD',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  {
    key = 'q',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
}
config.window_close_confirmation = 'NeverPrompt'
config.window_background_opacity = 0.5
config.macos_window_background_blur = 20
config.native_macos_fullscreen_mode = true
config.initial_cols = 120
config.initial_rows = 40

wezterm.on('window-resized', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local dimensions = window:get_dimensions()

  if dimensions.is_full_screen then
    overrides.window_background_opacity = 1
  else
    overrides.window_background_opacity = 0.5
  end

  window:set_config_overrides(overrides)
end)

return config
