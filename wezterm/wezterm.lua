local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

-- Load tabline plugin from local path
local tabline = wezterm.plugin.require("file://~/.config/wezterm/plugins/tabline.wez")

-- Window settings
config.window_padding = {
    left = 20,
    right = 20,
    top = 20,
    bottom = 20
}
config.enable_scroll_bar = true

config.color_scheme = "Catppuccin Macchiato"

config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20

-- Font configuration
config.font = wezterm.font_with_fallback {{
    family = 'Hack Nerd Font Mono',
    weight = 'Medium',
    harfbuzz_features = {'zero', 'ss01', 'liga'}
}, 'Symbols Nerd Font'}
config.font_size = 12.0
config.line_height = 1.0

-- Cursor settings
config.default_cursor_style = 'SteadyUnderline'
config.cursor_blink_rate = 800

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

-- Keybindings
config.keys = {{
    key = 'd',
    mods = 'CMD|SHIFT',
    action = act.SplitVertical {
        domain = 'CurrentPaneDomain'
    }
}, {
    key = 'd',
    mods = 'CMD',
    action = act.SplitHorizontal {
        domain = 'CurrentPaneDomain'
    }
}, {
    key = 'k',
    mods = 'CMD',
    action = act.ClearScrollback 'ScrollbackAndViewport'
}, {
    key = 'w',
    mods = 'CMD',
    action = act.CloseCurrentPane {
        confirm = false
    }
}, {
    key = 'w',
    mods = 'CMD|SHIFT',
    action = act.CloseCurrentTab {
        confirm = false
    }
}, {
    key = 'LeftArrow',
    mods = 'CMD',
    action = act.SendKey {
        key = 'Home'
    }
}, {
    key = 'RightArrow',
    mods = 'CMD',
    action = act.SendKey {
        key = 'End'
    }
}, {
    key = 'p',
    mods = 'CMD|SHIFT',
    action = act.ActivateCommandPalette
}}

-- Shell configuration
config.default_prog = {'/bin/zsh', '--login'}

-- Configure tabline
tabline.setup({
  options = {
    icons_enabled = true,
    theme = 'Catppuccin Macchiato',
    section_separators = {
      left = wezterm.nerdfonts.pl_left_hard_divider,
      right = wezterm.nerdfonts.pl_right_hard_divider,
    },
    component_separators = {
      left = wezterm.nerdfonts.pl_left_soft_divider,
      right = wezterm.nerdfonts.pl_right_soft_divider,
    },
  },
  sections = {
    tabline_a = { 'mode' },
    tabline_b = { 'workspace' },
    tabline_c = { ' ' },
    tab_active = {
      'index',
      { 'parent', padding = 0 },
      '/',
      { 'cwd', padding = { left = 0, right = 1 } },
      { 'zoomed', padding = 0 },
    },
    tab_inactive = { 'index', { 'process', padding = { left = 0, right = 1 } } },
    tabline_x = { 'ram', 'cpu' },
    tabline_y = { 'datetime', 'battery' },
    tabline_z = { 'domain' },
  },
})

-- Apply tabline config
tabline.apply_to_config(config)

return config
