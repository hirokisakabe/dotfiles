local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- see https://leaysgur.github.io/wezterm-colorscheme/
-- Iceberg (dark) - https://github.com/cocopon/iceberg.vim
config.color_scheme = 'iceberg-dark'

config.font = wezterm.font_with_fallback {
  { family = "OverpassM Nerd Font", assume_emoji_presentation = true },
  { family = "Moralerspace Argon", assume_emoji_presentation = true },
}

-- Iceberg dark palette
config.window_frame = {
  font = wezterm.font { family = "OverpassM Nerd Font" },
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

config.front_end = 'WebGpu'
config.freetype_load_flags = 'NO_HINTING'

config.font_size = 13.0
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

wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = pane.title
  local cwd = pane.current_working_directory
  if cwd then
    local path = cwd.file_path or tostring(cwd)
    local folder = path:match('([^/]+)/?$')
    if folder then
      return ' ' .. folder .. ': ' .. title .. ' '
    end
  end
  return ' ' .. title .. ' '
end)
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.native_macos_fullscreen_mode = true
config.initial_cols = 120
config.initial_rows = 40

return config
