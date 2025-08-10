local M = {}

local theme_state_dir = os.getenv("HOME") .. "/.local/state/sysinit/themes"
local current_theme_file = theme_state_dir .. "/current-theme.json"
local theme_cache_dir = theme_state_dir .. "/theme-cache"

-- Function to load JSON file
local function load_json(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local success, result = pcall(hs.json.decode, content)
  if success then
    return result
  else
    return nil
  end
end

-- Function to get current theme
local function get_current_theme()
  local theme_info = load_json(current_theme_file)
  if theme_info then
    return theme_info.colorscheme .. "-" .. theme_info.variant
  end
  return nil
end

-- Function to get available themes
local function get_available_themes()
  local themes = {}
  local handle = io.popen("find '" .. theme_cache_dir .. "' -maxdepth 1 -type d -exec basename {} \\; 2>/dev/null")

  if handle then
    for theme in handle:lines() do
      if theme ~= "theme-cache" and theme ~= "" and theme ~= "." then
        table.insert(themes, theme)
      end
    end
    handle:close()
  end

  table.sort(themes)
  return themes
end

-- Function to switch theme
local function switch_theme(theme_name)
  local cmd = "sysinit-theme switch " .. hs.shell.quote(theme_name)
  hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.notify.new({
        title = "Theme Switcher",
        informativeText = "Switched to: " .. theme_name,
        withdrawAfter = 3
      }):send()
    else
      hs.notify.new({
        title = "Theme Switcher",
        informativeText = "Failed to switch to: " .. theme_name,
        withdrawAfter = 5
      }):send()
    end
  end, { "bash", "-c", cmd }):start()
end

-- Function to show theme chooser
local function show_theme_chooser()
  local themes = get_available_themes()
  if #themes == 0 then
    hs.notify.new({
      title = "Theme Switcher",
      informativeText = "No themes available",
      withdrawAfter = 3
    }):send()
    return
  end

  local current = get_current_theme()
  local choices = {}

  for _, theme in ipairs(themes) do
    local choice = {
      text = theme,
      subText = theme == current and "Current theme" or ""
    }
    table.insert(choices, choice)
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      switch_theme(choice.text)
    end
  end)

  chooser:choices(choices)
  chooser:searchSubText(false)
  chooser:placeholderText("Select theme...")
  chooser:rows(math.min(10, #choices))
  chooser:show()
end

-- Function to cycle through themes
local function cycle_theme(direction)
  local themes = get_available_themes()
  if #themes <= 1 then
    return
  end

  local current = get_current_theme()
  local current_index = 1

  -- Find current theme index
  for i, theme in ipairs(themes) do
    if theme == current then
      current_index = i
      break
    end
  end

  -- Calculate next index
  local next_index
  if direction == "next" then
    next_index = current_index + 1
    if next_index > #themes then
      next_index = 1
    end
  else -- "previous"
    next_index = current_index - 1
    if next_index < 1 then
      next_index = #themes
    end
  end

  switch_theme(themes[next_index])
end

-- Function to show current theme
local function show_current_theme()
  local current = get_current_theme()
  if current then
    hs.notify.new({
      title = "Current Theme",
      informativeText = current,
      withdrawAfter = 3
    }):send()
  else
    hs.notify.new({
      title = "Theme Switcher",
      informativeText = "No current theme found",
      withdrawAfter = 3
    }):send()
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Default keybindings
  local mods = opts.mods or {"cmd", "alt"}
  local show_chooser_key = opts.show_chooser_key or "t"
  local next_theme_key = opts.next_theme_key or "n"
  local prev_theme_key = opts.prev_theme_key or "p"
  local current_theme_key = opts.current_theme_key or "c"

  -- Bind keys
  hs.hotkey.bind(mods, show_chooser_key, function()
    show_theme_chooser()
  end)

  hs.hotkey.bind(mods, next_theme_key, function()
    cycle_theme("next")
  end)

  hs.hotkey.bind(mods, prev_theme_key, function()
    cycle_theme("previous")
  end)

  hs.hotkey.bind(mods, current_theme_key, function()
    show_current_theme()
  end)

  hs.console.printStyledtext("Theme Switcher loaded with keybindings:\n")
  hs.console.printStyledtext("  " .. table.concat(mods, "+") .. "+" .. show_chooser_key .. " - Show theme chooser\n")
  hs.console.printStyledtext("  " .. table.concat(mods, "+") .. "+" .. next_theme_key .. " - Next theme\n")
  hs.console.printStyledtext("  " .. table.concat(mods, "+") .. "+" .. prev_theme_key .. " - Previous theme\n")
  hs.console.printStyledtext("  " .. table.concat(mods, "+") .. "+" .. current_theme_key .. " - Show current theme\n")
end

-- Public API
M.switch_theme = switch_theme
M.get_current_theme = get_current_theme
M.get_available_themes = get_available_themes
M.show_theme_chooser = show_theme_chooser
M.cycle_theme = cycle_theme
M.show_current_theme = show_current_theme

return M
