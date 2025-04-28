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

-- Fix for the update-status event handler
wezterm.on('update-status', function(window)
    -- Get current working directory from active pane
    local success, cwd, _ = pcall(function()
        return window:active_pane():get_current_working_dir()
    end)

    local cwd_display = '~'
    if success and cwd then
        -- Format the path for display
        cwd_display = cwd:gsub('file://[^/]+', ''):gsub(wezterm.home_dir, '~')
    end

    -- Get hostname safely
    local hostname = wezterm.hostname()

    -- Get current kubernetes context using kubectl
    local success_kube, kube_context_stdout, _ = wezterm.run_child_process({'zsh', '-c',
                                                                            "kubectl config current-context"})
    local kube_context = "none"
    if success_kube then
        kube_context = kube_context_stdout:gsub("[\r\n]+$", "") -- Trim trailing newlines
    end

    -- Get current GitHub user using gh-whoami
    local success_gh, gh_user_stdout, _ = wezterm.run_child_process({"zsh", "-c", "gh-whoami"})
    local gh_user = "unknown"
    if success_gh then
        gh_user = gh_user_stdout:gsub("[\r\n]+$", "") -- Trim trailing newlines
    end

    -- Create status elements
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
    }, {
        Foreground = {
            Color = "#cba6f7"
        },
        Text = "󱃾 " .. kube_context
    }, {
        Foreground = {
            Color = "#f5c2e7"
        },
        Text = " > "
    }, {
        Foreground = {
            Color = "#fab387"
        },
        Text = " " .. gh_user
    }}

    -- Set the right status with the formatted elements
    window:set_right_status(wezterm.format(elements))
end)

-- Fix for the gui-startup event handler
wezterm.on("gui-startup", function(cmd)
    -- Get active screen information
    local screen = wezterm.gui.screens().active
    if not screen then
        return -- Exit if no active screen is found
    end

    -- Create a new window with the specified command or default
    local _, _, window = wezterm.mux.spawn_window(cmd or {})

    -- Position and size the window to match the screen
    local gui_window = window:gui_window()
    if gui_window then
        gui_window:set_position(screen.x, screen.y)
        gui_window:set_inner_size(screen.width, screen.height)
    end
end)

return config
