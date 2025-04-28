local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

-- Shell configuration
config.default_prog = {'/bin/zsh', '-l'}
config.set_environment_variables = {
    SHELL = '/bin/zsh',
    TERM = 'wezterm'
}

-- Window settings
config.window_padding = {
    left = 20,
    right = 0,
    top = 20,
    bottom = 20
}

config.enable_scroll_bar = true
config.scrollback_lines = 20000
config.window_background_opacity = 0.85
config.macos_window_background_blur = 50
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'

-- Visual bell
config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 35,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 50
}

config.colors = {
    visual_bell = '#242529'
}

-- Theme
config.color_scheme = "Catppuccin Mocha"

-- Font configuration
config.font = wezterm.font_with_fallback({{
    family = 'Hack Nerd Font Mono',
    weight = 'Medium',
    harfbuzz_features = {'zero', 'ss01', 'liga'}
}, 'Symbols Nerd Font'})
config.font_size = 12.0
config.line_height = 1.0

-- Cursor settings
config.default_cursor_style = 'SteadyUnderline'
config.cursor_blink_rate = 300

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

-- Disable defaults
config.disable_default_key_bindings = true

-- Key bindings
config.keys = { -- Split creation
{
    key = 'v',
    mods = 'CMD|SHIFT',
    action = act.SplitHorizontal {
        domain = 'CurrentPaneDomain'
    }
}, {
    key = 's',
    mods = 'CMD|SHIFT',
    action = act.SplitVertical {
        domain = 'CurrentPaneDomain'
    }
}, -- Common actions
{
    key = 'k',
    mods = 'CMD',
    action = act.ClearScrollback 'ScrollbackAndViewport'
}, {
    key = 'p',
    mods = 'CMD|SHIFT',
    action = act.ActivateCommandPalette
}, {
    key = 'y',
    mods = 'CMD',
    action = act.ActivateCopyMode
}, {
    key = 'r',
    mods = 'CMD',
    action = act.ReloadConfiguration
}, {
    key = 'w',
    mods = 'CMD',
    action = act.CloseCurrentPane {
        confirm = false
    }
}, -- Standard Mac keybindings
{
    key = 'c',
    mods = 'CMD',
    action = act.CopyTo 'Clipboard'
}, {
    key = 'v',
    mods = 'CMD',
    action = act.PasteFrom 'Clipboard'
}, {
    key = 'm',
    mods = 'CMD',
    action = act.Hide
}, {
    key = 'n',
    mods = 'CMD',
    action = act.SpawnWindow
}, {
    key = 't',
    mods = 'CMD',
    action = act.SpawnTab 'CurrentPaneDomain'
}, {
    key = 'f',
    mods = 'CMD',
    action = act.Search 'CurrentSelectionOrEmptyString'
}, {
    key = 'h',
    mods = 'CMD',
    action = act.HideApplication
}, {
    key = 'q',
    mods = 'CMD',
    action = act.QuitApplication
}, -- Tab navigation
{
    key = '1',
    mods = 'CMD',
    action = act.ActivateTab(0)
}, {
    key = '2',
    mods = 'CMD',
    action = act.ActivateTab(1)
}, {
    key = '3',
    mods = 'CMD',
    action = act.ActivateTab(2)
}, {
    key = '4',
    mods = 'CMD',
    action = act.ActivateTab(3)
}, {
    key = '5',
    mods = 'CMD',
    action = act.ActivateTab(4)
}, {
    key = '6',
    mods = 'CMD',
    action = act.ActivateTab(5)
}, {
    key = '7',
    mods = 'CMD',
    action = act.ActivateTab(6)
}, {
    key = '8',
    mods = 'CMD',
    action = act.ActivateTab(7)
}, {
    key = '9',
    mods = 'CMD',
    action = act.ActivateTab(-1)
}, {
    key = '{',
    mods = 'CMD|SHIFT',
    action = act.ActivateTabRelative(-1)
}, {
    key = '}',
    mods = 'CMD|SHIFT',
    action = act.ActivateTabRelative(1)
}, -- Font size
{
    key = '-',
    mods = 'CMD',
    action = act.DecreaseFontSize
}, {
    key = '=',
    mods = 'CMD',
    action = act.IncreaseFontSize
}, {
    key = '0',
    mods = 'CMD',
    action = act.ResetFontSize
}, -- Alternative pane navigation
{
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

-- Copy mode and search mode key tables
config.key_tables = {
    -- We dont use this!
    copy_mode = {},

    search_mode = {{
        key = 'Enter',
        mods = 'NONE',
        action = act.CopyMode 'PriorMatch'
    }, {
        key = 'Escape',
        mods = 'NONE',
        action = act.CopyMode 'Close'
    }, {
        key = 'n',
        mods = 'CMD',
        action = act.CopyMode 'NextMatch'
    }, {
        key = 'p',
        mods = 'CMD',
        action = act.CopyMode 'PriorMatch'
    }, {
        key = 'r',
        mods = 'CMD',
        action = act.CopyMode 'CycleMatchType'
    }, {
        key = 'u',
        mods = 'CMD',
        action = act.CopyMode 'ClearPattern'
    }, {
        key = 'PageUp',
        mods = 'NONE',
        action = act.CopyMode 'PriorMatchPage'
    }, {
        key = 'PageDown',
        mods = 'NONE',
        action = act.CopyMode 'NextMatchPage'
    }, {
        key = 'UpArrow',
        mods = 'NONE',
        action = act.CopyMode 'PriorMatch'
    }, {
        key = 'DownArrow',
        mods = 'NONE',
        action = act.CopyMode 'NextMatch'
    }}
}

wezterm.on('update-status', function(window, _)
    local cwd = window:active_pane():get_current_working_dir()
    local hostname = wezterm.hostname()

    local cwd_display = cwd and cwd:gsub('file://[^/]+', ''):gsub(os.getenv('HOME'), '~') or '~'

    local elements = {{
        Foreground = {
            Color = "#89b4fa"
        },
        Text = "󰉋 " .. cwd_display
    }, {
        Foreground = {
            Color = "#f5c2e7"
        },
        Text = " > "
    }, {
        Foreground = {
            Color = "#a6e3a1"
        },
        Text = "󱄅 " .. hostname
    }, {
        Foreground = {
            Color = "#f5c2e7"
        },
        Text = " > "
    }}

    window:set_right_status(wezterm.format(elements))
end)

wezterm.on("gui-startup", function(cmd)
    local active = wezterm.gui.screens().active
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    window:guiwindow():setposition(active.x, active.y)
    window:guiwindow():set_innersize(active.width, active.height)
end)

return config
