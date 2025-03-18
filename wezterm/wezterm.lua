local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

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
config.window_background_opacity = 0.3
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

return config
