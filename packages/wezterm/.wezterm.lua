local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- see https://leaysgur.github.io/wezterm-colorscheme/
config.color_scheme = 'Ubuntu'

config.font = wezterm.font_with_fallback {
  { family = "UbuntuMono Nerd Font", assume_emoji_presentation = true },
  { family = "Moralerspace Argon", assume_emoji_presentation = true },
}

config.window_frame = {
  font = wezterm.font { family = "UbuntuMono Nerd Font" },
  active_titlebar_bg = '#300a24',
  inactive_titlebar_bg = '#2c001e',
}

config.colors = {
  tab_bar = {
    active_tab = {
      bg_color = '#300a24',
      fg_color = '#ffffff',
    },
    inactive_tab = {
      bg_color = '#2c001e',
      fg_color = '#808080',
    },
    inactive_tab_hover = {
      bg_color = '#5e2750',
      fg_color = '#ffffff',
    },
    new_tab = {
      bg_color = '#2c001e',
      fg_color = '#808080',
    },
    new_tab_hover = {
      bg_color = '#5e2750',
      fg_color = '#ffffff',
    },
  },
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
