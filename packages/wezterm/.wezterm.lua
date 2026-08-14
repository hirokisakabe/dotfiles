local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

local background = '#f7f8f8'
local surface = '#eceff0'
local foreground = '#1f2326'
local muted = '#737a7e'
local accent = '#1f2326'

-- Atrium Library: cool architectural whites, black details, and open space.
config.color_schemes = {
  ['Atrium Library'] = {
    foreground = foreground,
    background = background,
    cursor_bg = accent,
    cursor_fg = background,
    cursor_border = accent,
    selection_fg = foreground,
    selection_bg = '#dce1e3',
    split = '#cbd1d4',
    ansi = {
      '#292b2d',
      '#945f5f',
      '#687768',
      '#827458',
      '#687078',
      '#756d7a',
      '#657575',
      '#dfe1e0',
    },
    brights = {
      '#767b80',
      '#a36d6d',
      '#768576',
      '#908266',
      '#767e86',
      '#837b88',
      '#738383',
      '#ffffff',
    },
  },
}
config.color_scheme = 'Atrium Library'

config.font = wezterm.font_with_fallback {
  { family = "OverpassM Nerd Font" },
  { family = "Moralerspace Argon" },
}

config.window_frame = {
  font = wezterm.font { family = "OverpassM Nerd Font" },
  font_size = 15.0,
  active_titlebar_bg = surface,
  inactive_titlebar_bg = surface,
}

config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.tab_max_width = 44
config.window_padding = {
  left = 16,
  right = 16,
  top = 12,
  bottom = 14,
}

config.colors = {
  tab_bar = {
    background = surface,
    active_tab = {
      bg_color = background,
      fg_color = foreground,
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = surface,
      fg_color = muted,
    },
    inactive_tab_hover = {
      bg_color = '#dfe3e5',
      fg_color = foreground,
    },
    new_tab = {
      bg_color = surface,
      fg_color = muted,
    },
    new_tab_hover = {
      bg_color = '#dfe3e5',
      fg_color = foreground,
    },
  },
}
config.inactive_pane_hsb = {
  saturation = 0.6,
  brightness = 0.96,
}

config.front_end = 'WebGpu'
config.freetype_load_flags = 'NO_HINTING'

config.font_size = 13.0
config.line_height = 1.08
config.cell_width = 1.01
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

wezterm.on('format-tab-title', function(tab, tabs, panes, tab_config, hover, max_width)
  local pane = tab.active_pane
  local title = pane.title
  local cwd = pane.current_working_dir
  if cwd then
    local path = cwd.file_path or tostring(cwd)
    title = path:match('([^/]+)/?$') or title
  end

  title = wezterm.truncate_right(title, max_width - 6)
  return '   ' .. title .. '   '
end)

config.window_background_opacity = 1.0
config.macos_window_background_blur = 0
config.native_macos_fullscreen_mode = true
config.initial_cols = 120
config.initial_rows = 40

return config
