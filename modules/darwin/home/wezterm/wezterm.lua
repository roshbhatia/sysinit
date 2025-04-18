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

config.window_background_opacity = 0.85
config.macos_window_background_blur = 50
config.window_decorations = 'RESIZE'

-- Font configuration: use single primary font with symbol fallback for consistent metrics
config.font = wezterm.font_with_fallback({
  { family = 'Hack Nerd Font Mono', weight = 'Medium', harfbuzz_features = {'zero', 'ss01', 'liga'} },
  'Symbols Nerd Font',
})
config.font_size = 12.0
-- Adjust line height for consistent vertical spacing
config.line_height = 1.0

-- Cursor settings
config.default_cursor_style = 'SteadyUnderline'
config.cursor_blink_rate = 800

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

config.window_close_confirmation = 'NeverPrompt'

smart_splits.apply_to_config(config, {
    -- directional keys to use in order of: left, down, up, right
    direction_keys = { 'h', 'j', 'k', 'l' },
    -- modifier keys to combine with direction_keys
    modifiers = {
        move = 'CMD|SHIFT', -- modifier for pane movement
        resize = 'CMD|ALT', -- modifier for pane resize
    },
})

-- Disable defaults here
config.disable_default_key_bindings = true

config.keys = {
    -- Your custom keybindings
    { key = 's', mods = 'CMD|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'v', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
    { key = 'y', mods = 'CMD', action = act.ActivateCopyMode },
    { key = 'r', mods = 'CMD', action = act.ReloadConfiguration },
    { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = false } },

    -- Standard Mac keybindings
    { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },
    { key = 'm', mods = 'CMD', action = act.Hide },
    { key = 'n', mods = 'CMD', action = act.SpawnWindow },
    { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'f', mods = 'CMD', action = act.Search 'CurrentSelectionOrEmptyString' },
    { key = 'h', mods = 'CMD', action = act.HideApplication },
    { key = 'q', mods = 'CMD', action = act.QuitApplication },

    -- Tab navigation
    { key = '1', mods = 'CMD', action = act.ActivateTab(0) },
    { key = '2', mods = 'CMD', action = act.ActivateTab(1) },
    { key = '3', mods = 'CMD', action = act.ActivateTab(2) },
    { key = '4', mods = 'CMD', action = act.ActivateTab(3) },
    { key = '5', mods = 'CMD', action = act.ActivateTab(4) },
    { key = '6', mods = 'CMD', action = act.ActivateTab(5) },
    { key = '7', mods = 'CMD', action = act.ActivateTab(6) },
    { key = '8', mods = 'CMD', action = act.ActivateTab(7) },
    { key = '9', mods = 'CMD', action = act.ActivateTab(-1) },
    { key = '{', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = '}', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },

    -- Font size
    { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
    { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
    { key = '0', mods = 'CMD', action = act.ResetFontSize },

    -- Other useful actions
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },

    -- Pane navigation
    { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection 'Down' },

    -- Pane resizing
    { key = 'LeftArrow', mods = 'CMD|SHIFT|ALT', action = act.AdjustPaneSize{ 'Left', 1 } },
    { key = 'RightArrow', mods = 'CMD|SHIFT|ALT', action = act.AdjustPaneSize{ 'Right', 1 } },
    { key = 'UpArrow', mods = 'CMD|SHIFT|ALT', action = act.AdjustPaneSize{ 'Up', 1 } },
    { key = 'DownArrow', mods = 'CMD|SHIFT|ALT', action = act.AdjustPaneSize{ 'Down', 1 } },

    -- Pane/viewport scroll
    { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },

    -- Pane zooming
    { key = 'z', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },
}

-- Keep the copy_mode and search_mode key tables (modified for Mac)
config.key_tables = {
    copy_mode = {
        { key = 'Tab', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
        { key = 'Tab', mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },
        { key = 'Enter', mods = 'NONE', action = act.CopyMode 'MoveToStartOfNextLine' },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
        { key = 'Space', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Cell' } },
        { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
        { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
        { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
        { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
        { key = 'F', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
        { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
        { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
        { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
        { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
        { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
        { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
        { key = 'V', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Line' } },
        { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
        { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
        { key = 'b', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
        { key = 'b', mods = 'CMD', action = act.CopyMode 'PageUp' },
        { key = 'c', mods = 'CMD', action = act.CopyMode 'Close' },
        { key = 'd', mods = 'CMD', action = act.CopyMode{ MoveByPage = (0.5) } },
        { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },
        { key = 'f', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = false } } },
        { key = 'f', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
        { key = 'f', mods = 'CMD', action = act.CopyMode 'PageDown' },
        { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
        { key = 'g', mods = 'CMD', action = act.CopyMode 'Close' },
        { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
        { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
        { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
        { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
        { key = 'm', mods = 'ALT', action = act.CopyMode 'MoveToStartOfLineContent' },
        { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
        { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },
        { key = 't', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = true } } },
        { key = 'u', mods = 'CMD', action = act.CopyMode{ MoveByPage = (-0.5) } },
        { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Cell' } },
        { key = 'v', mods = 'CMD', action = act.CopyMode{ SetSelectionMode = 'Block' } },
        { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
        { key = 'y', mods = 'NONE', action = act.Multiple{ { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } } },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
        { key = 'End', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
        { key = 'Home', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
        { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
        { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
        { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
        { key = 'RightArrow', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
    }

    search_mode = {
        { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
        { key = 'n', mods = 'CMD', action = act.CopyMode 'NextMatch' },
        { key = 'p', mods = 'CMD', action = act.CopyMode 'PriorMatch' },
        { key = 'r', mods = 'CMD', action = act.CopyMode 'CycleMatchType' },
        { key = 'u', mods = 'CMD', action = act.CopyMode 'ClearPattern' },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
    }
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
