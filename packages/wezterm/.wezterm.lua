local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- see https://leaysgur.github.io/wezterm-colorscheme/
-- Iceberg (dark) - https://github.com/cocopon/iceberg.vim
config.color_scheme = 'iceberg-dark'

config.font = wezterm.font_with_fallback {
  { family = "JetBrainsMono Nerd Font", assume_emoji_presentation = true },
  { family = "Moralerspace Argon", assume_emoji_presentation = true },
}

-- Iceberg dark palette
config.window_frame = {
  font = wezterm.font { family = "JetBrainsMono Nerd Font" },
  active_titlebar_bg = '#0f1117',
  inactive_titlebar_bg = '#161821',
}

config.colors = {
  tab_bar = {
    active_tab = {
      bg_color = '#1e2132',
      fg_color = '#c6c8d1',
    },
    inactive_tab = {
      bg_color = '#161821',
      fg_color = '#6b7089',
    },
    inactive_tab_hover = {
      bg_color = '#1e2132',
      fg_color = '#c6c8d1',
    },
    new_tab = {
      bg_color = '#161821',
      fg_color = '#6b7089',
    },
    new_tab_hover = {
      bg_color = '#1e2132',
      fg_color = '#c6c8d1',
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
