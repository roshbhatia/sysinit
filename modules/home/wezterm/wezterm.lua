local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()

-- Shell configuration
config.default_prog = { '/bin/zsh', '-l' }
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

config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 35,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 50
}

config.color_scheme = "apprentice-bright"

config.colors = {
    visual_bell = '#242529',
}

config.window_background_opacity = 0.8
config.macos_window_background_blur = 20
config.window_decorations = 'RESIZE'

-- Font configuration
config.font = wezterm.font_with_fallback {{
    family = 'Hack Nerd Font Mono', 
    weight = 'Medium',
    harfbuzz_features = {'zero', 'ss01', 'liga'}
}, {
    family = 'Hack Nerd Font Mono',
    weight = 'Medium',
}, 'Symbols Nerd Font'}
config.font_size = 12.0
config.line_height = 1.1

-- Cursor settings
config.default_cursor_style = 'SteadyUnderline'
config.cursor_blink_rate = 800

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

-- Keybindings
config.keys = {
    -- Word/Line navigation (using CMD+SHIFT instead of ALT to avoid conflicts with aerospace)
    { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.SendKey { key = 'b', mods = 'ALT' } },
    { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.SendKey { key = 'f', mods = 'ALT' } },
    { key = 'UpArrow', mods = 'CMD|SHIFT', action = act.SendKey { key = 'e', mods = 'CTRL' } },
    { key = 'DownArrow', mods = 'CMD|SHIFT', action = act.SendKey { key = 'a', mods = 'CTRL' } },

    -- Pane management
    { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = false } },
    { key = 'w', mods = 'CMD|SHIFT', action = act.CloseCurrentTab { confirm = false } },

    -- Pane navigation with CMD+arrows (for fallback)
    { key = 'LeftArrow', mods = 'CMD', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CMD', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'CMD', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'CMD', action = act.ActivatePaneDirection 'Down' },
    
    -- Smart-splits.nvim integration with Ctrl+h/j/k/l
    { key = 'h', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'h', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.ActivatePaneDirection 'Left', pane)
        end
    end)},
    { key = 'j', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'j', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.ActivatePaneDirection 'Down', pane)
        end
    end)},
    { key = 'k', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'k', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.ActivatePaneDirection 'Up', pane)
        end
    end)},
    { key = 'l', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'l', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.ActivatePaneDirection 'Right', pane)
        end
    end)},
    
    -- Add resize keybindings for smart-splits.nvim using arrow keys instead of ALT
    { key = 'LeftArrow', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'LeftArrow', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.AdjustPaneSize { 'Left', 3 }, pane)
        end
    end)},
    { key = 'DownArrow', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'DownArrow', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.AdjustPaneSize { 'Down', 3 }, pane)
        end
    end)},
    { key = 'UpArrow', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'UpArrow', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.AdjustPaneSize { 'Up', 3 }, pane)
        end
    end)},
    { key = 'RightArrow', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
        if pane:get_user_vars().IS_NVIM == 'true' then
            window:perform_action(act.SendKey { key = 'RightArrow', mods = 'CTRL' }, pane)
        else
            window:perform_action(act.AdjustPaneSize { 'Right', 3 }, pane)
        end
    end)},

    -- Special commands
    { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
    { key = 'f', mods = 'CMD|SHIFT', action = wezterm.action.ActivateCopyMode },
    { key = 'r', mods = 'CMD', action = act.ReloadConfiguration }
}

wezterm.on("gui-startup", function()
    local tab, pane, window = wezterm.mux.spawn_window {}
    window:gui_window():maximize()
end)

-- Enhanced powerline configuration
local function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end

local function is_dark_mode()
    return get_appearance():find('Dark') and true or false
end

-- Define powerline characters
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

-- Function to create powerline segments for right status
local function segments_for_right_status(window)
    -- Return segments in order
    return {
        { text = wezterm.hostname(), foreground = "#8be9fd", background = "#3b4048" },
    }
end

wezterm.on('update-status', function(window, _)
    local segments = segments_for_right_status(window)
    local elements = {}
    
    -- Build the right status elements with powerline separators
    for i, segment in ipairs(segments) do
        local is_last = i == #segments
        
        if i > 1 then
            -- Add powerline arrow between segments
            table.insert(elements, {Foreground = {Color = segment.background}})
            table.insert(elements, {Background = {Color = segments[i-1].background}})
            table.insert(elements, {Text = SOLID_LEFT_ARROW})
        end
        
        -- Add the segment text
        table.insert(elements, {Foreground = {Color = segment.foreground}})
        table.insert(elements, {Background = {Color = segment.background}})
        table.insert(elements, {Text = " " .. segment.text .. " "})
        
        -- Add final arrow for the last segment
        if is_last then
            table.insert(elements, {Foreground = {Color = "background"}})
            table.insert(elements, {Background = {Color = segment.background}})
            table.insert(elements, {Text = SOLID_LEFT_ARROW})
        end
    end
    
    -- Set right status
    window:set_right_status(wezterm.format(elements))
    
    -- Also enhance the left status (optional)
    local left_elements = {}
    
    -- Get current working directory
    local cwd = ""
    local success, cwd_uri, cwd_domain = pcall(window.active_pane.get_current_working_dir, window:active_pane())
    if success then
        cwd = cwd_uri.file_path
        -- Shorten home directory
        cwd = cwd:gsub(os.getenv("HOME"), "~")
        -- Get just the last part of the path
        if cwd ~= "~" then
            local parts = {}
            for part in cwd:gmatch("[^/]+") do
                table.insert(parts, part)
            end
            if #parts > 0 then
                cwd = parts[#parts]
            end
        end
    end
    
    -- Add directory to left status
    if cwd ~= "" then
        table.insert(left_elements, {Foreground = {Color = "#bd93f9"}})
        table.insert(left_elements, {Background = {Color = "#282c34"}})
        table.insert(left_elements, {Text = " 󰉋 " .. cwd .. " "})
        
        table.insert(left_elements, {Foreground = {Color = "#282c34"}})
        table.insert(left_elements, {Background = {Color = "background"}})
        table.insert(left_elements, {Text = SOLID_RIGHT_ARROW})
    end
    
    window:set_left_status(wezterm.format(left_elements))
end)

return config
