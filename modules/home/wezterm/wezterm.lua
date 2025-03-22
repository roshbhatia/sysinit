-- THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
--                             888                                
--                             888                                
--                             888                                
-- 888  888  888 .d88b. 88888888888888 .d88b. 888d88888888b.d88b.  
-- 888  888  888d8P  Y8b   d88P 888   d8P  Y8b888P"  888 "888 "88b 
-- 888  888  88888888888  d88P  888   88888888888    888  888  888 
-- Y88b 888 d88PY8b.     d88P   Y88b. Y8b.    888    888  888  888 
--  "Y8888888P"  "Y8888 88888888 "Y888 "Y8888 888    888  888  888
local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

-- Window settings
config.window_padding = {
    left = 20,
    right = 0,
    top = 20,
    bottom = 20
}

config.enable_scroll_bar = true
config.scrollback_lines = 20000

config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 25,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 25
}

config.color_scheme = "Apple System Colors"

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
config.keys = { -- Word navigation
{
    key = 'LeftArrow',
    mods = 'ALT',
    action = act.SendKey {
        key = 'b',
        mods = 'ALT'
    }
}, {
    key = 'RightArrow',
    mods = 'ALT',
    action = act.SendKey {
        key = 'f',
        mods = 'ALT'
    }
}, -- Line navigation
{
    key = 'LeftArrow',
    mods = 'SHIFT|ALT',
    action = act.SendKey {
        key = 'a',
        mods = 'CTRL'
    }
}, {
    key = 'RightArrow',
    mods = 'SHIFT|ALT',
    action = act.SendKey {
        key = 'e',
        mods = 'CTRL'
    }
}, -- Existing keybindings
{
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
}, {
    key = 'LeftArrow',
    mods = 'CMD|SHIFT',
    action = act.ActivatePaneDirection 'Left'
}, {
    key = 'RightArrow',
    mods = 'CMD|SHIFT',
    action = act.ActivatePaneDirection 'Right'
}, {
    key = 'UpArrow',
    mods = 'CMD|SHIFT',
    action = act.ActivatePaneDirection 'Up'
}, {
    key = 'DownArrow',
    mods = 'CMD|SHIFT',
    action = act.ActivatePaneDirection 'Down'
}}

wezterm.on("gui-startup", function()
    local tab, pane, window = wezterm.mux.spawn_window {}
    window:gui_window():maximize()
end)

return config
