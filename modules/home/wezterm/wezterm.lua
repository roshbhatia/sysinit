local wezterm = require('wezterm')
local act = wezterm.action
local config = wezterm.config_builder()
local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')

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

config.color_scheme = "Abernathy"

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

config.window_close_confirmation = 'NeverPrompt'

-- Apply smart-splits configuration
smart_splits.apply_to_config(config, {
    -- directional keys to use in order of: left, down, up, right
    direction_keys = { 'h', 'j', 'k', 'l' },
    -- modifier keys to combine with direction_keys
    modifiers = {
        move = 'CMD|SHIFT', -- modifier for pane movement
        resize = 'CMD|ALT', -- modifier for pane resize
    },
})

-- Additional keybindings
local additional_keys = {
    { key = 's', mods = 'CMD|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'v', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'l', mods = 'CTRL', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
    { key = 'y', mods = 'CMD', action = wezterm.action.ActivateCopyMode },
    { key = 'r', mods = 'CMD', action = act.ReloadConfiguration },
    { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentPane { confirm = false } }
}

-- Merge additional keybindings with smart-splits keybindings
config.keys = additional_keys

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
    local segments = {}
    
    -- Get current working directory for first segment
    local cwd = ""
    local success, cwd_uri = pcall(window.active_pane.get_current_working_dir, window:active_pane())
    if success then
        cwd = cwd_uri.file_path:gsub(os.getenv("HOME"), "~")
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
    
    -- Add directory segment
    if cwd ~= "" then
        table.insert(segments, { text = "󰉋 " .. cwd, foreground = "#bd93f9", background = "#282c34" })
    end
    
    -- Add hostname segment
    table.insert(segments, { text = wezterm.hostname(), foreground = "#8be9fd", background = "#3b4048" })
    
    return segments
end

wezterm.on('update-status', function(window, _)
    local segments = segments_for_right_status(window)
    local elements = {}
    
    -- Build the right status elements with powerline separators
    for i, segment in ipairs(segments) do
        local is_last = i == #segments
        
        if i > 1 then
            table.insert(elements, {Foreground = {Color = segment.background}})
            table.insert(elements, {Background = {Color = segments[i-1].background}})
            table.insert(elements, {Text = SOLID_LEFT_ARROW})
        end
        
        table.insert(elements, {Foreground = {Color = segment.foreground}})
        table.insert(elements, {Background = {Color = segment.background}})
        table.insert(elements, {Text = " " .. segment.text .. " "})
        
        if is_last then
            table.insert(elements, {Foreground = {Color = "background"}})
            table.insert(elements, {Background = {Color = segment.background}})
            table.insert(elements, {Text = SOLID_LEFT_ARROW})
        end
    end
    
    window:set_right_status(wezterm.format(elements))
    window:set_left_status("") -- Clear left status
end)

return config
