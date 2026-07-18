local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

local tab_bar_background = '#d7f1f8'
local left_cap = utf8.char(0xe0b6)
local right_cap = utf8.char(0xe0b4)

-- Frosted Aqua: a pale blue, translucent palette inspired by Liquid Glass.
config.color_schemes = {
  ['Frosted Aqua'] = {
    foreground = '#203b52',
    background = '#ddf4fa',
    cursor_bg = '#4c87c7',
    cursor_fg = '#f4fbfd',
    cursor_border = '#4c87c7',
    selection_fg = '#12283a',
    selection_bg = 'rgba(114, 199, 232, 48%)',
    split = '#8abdd0',
    ansi = {
      '#203b52',
      '#b84f68',
      '#3f8969',
      '#966824',
      '#4c87c7',
      '#8076b3',
      '#378a9b',
      '#c7eaf6',
    },
    brights = {
      '#6d8496',
      '#c65f77',
      '#4b9b79',
      '#a57432',
      '#5e9bd9',
      '#9187c2',
      '#45a0b1',
      '#f4fbfd',
    },
  },
}
config.color_scheme = 'Frosted Aqua'

config.font = wezterm.font_with_fallback {
  { family = "OverpassM Nerd Font" },
  { family = "Moralerspace Argon" },
}

config.window_frame = {
  font = wezterm.font { family = "OverpassM Nerd Font" },
  active_titlebar_bg = '#c7eaf6',
  inactive_titlebar_bg = '#d7f1f8',
}

config.use_fancy_tab_bar = false
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.tab_max_width = 32
config.window_padding = {
  left = 10,
  right = 10,
  top = 6,
  bottom = 8,
}

config.colors = {
  tab_bar = {
    background = tab_bar_background,
    active_tab = {
      bg_color = '#d7f1f8',
      fg_color = '#203b52',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#d7f1f8',
      fg_color = '#63869a',
    },
    inactive_tab_hover = {
      bg_color = '#d7f1f8',
      fg_color = '#4c87c7',
    },
    new_tab = {
      bg_color = '#c7eaf6',
      fg_color = '#4c87c7',
    },
    new_tab_hover = {
      bg_color = '#a9dceb',
      fg_color = '#12283a',
    },
  },
}

local function rounded_tab_button(background, foreground, text)
  return wezterm.format {
    { Background = { Color = tab_bar_background } },
    { Text = ' ' },
    { Foreground = { Color = background } },
    { Text = left_cap },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = ' ' .. text .. ' ' },
    { Background = { Color = tab_bar_background } },
    { Foreground = { Color = background } },
    { Text = right_cap },
  }
end

config.tab_bar_style = {
  new_tab = rounded_tab_button('#c7eaf6', '#4c87c7', '+'),
  new_tab_hover = rounded_tab_button('#a9dceb', '#12283a', '+'),
}

config.window_background_gradient = {
  orientation = { Linear = { angle = -35.0 } },
  colors = { '#e8f8fc', '#c7eaf6', '#d9f3f9' },
  interpolation = 'Linear',
  blend = 'Rgb',
}
config.inactive_pane_hsb = {
  saturation = 0.75,
  brightness = 0.92,
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

wezterm.on('format-tab-title', function(tab, tabs, panes, tab_config, hover, max_width)
  local pane = tab.active_pane
  local title = pane.title
  local cwd = pane.current_working_dir
  if cwd then
    local path = cwd.file_path or tostring(cwd)
    local folder = path:match('([^/]+)/?$')
    if folder then
      title = folder
    end
  end

  local background = '#c7eaf6'
  local foreground = '#4b6b7e'
  if tab.is_active then
    background = '#93d2ea'
    foreground = '#12283a'
  elseif hover then
    background = '#a9dceb'
    foreground = '#203b52'
  end

  title = wezterm.truncate_right(title, max_width - 5)

  return {
    { Background = { Color = tab_bar_background } },
    { Text = ' ' },
    { Foreground = { Color = background } },
    { Text = left_cap },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Text = ' ' .. title .. ' ' },
    { Background = { Color = tab_bar_background } },
    { Foreground = { Color = background } },
    { Text = right_cap },
  }
end)
config.window_background_opacity = 0.8
config.macos_window_background_blur = 32
config.native_macos_fullscreen_mode = true
config.initial_cols = 120
config.initial_rows = 40

local function adjust_fullscreen_background(window)
  local window_dims = window:get_dimensions()
  local overrides = window:get_config_overrides() or {}

  if window_dims.is_full_screen then
    if
      overrides.window_background_opacity == 1.0
      and overrides.macos_window_background_blur == 0
    then
      return
    end
    overrides.window_background_opacity = 1.0
    overrides.macos_window_background_blur = 0
  else
    if
      overrides.window_background_opacity == nil
      and overrides.macos_window_background_blur == nil
    then
      return
    end
    overrides.window_background_opacity = nil
    overrides.macos_window_background_blur = nil
  end

  window:set_config_overrides(overrides)
end

wezterm.on('window-resized', function(window)
  adjust_fullscreen_background(window)
end)

wezterm.on('window-config-reloaded', function(window)
  adjust_fullscreen_background(window)
end)

return config
