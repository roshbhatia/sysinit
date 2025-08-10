local M = {}

local theme_state_file = vim.fn.expand("~/.local/state/sysinit/themes/current-theme.json")
local theme_cache_dir = vim.fn.expand("~/.local/state/sysinit/themes/theme-cache")

function M.load_current_theme()
  local file = io.open(theme_state_file, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local success, theme_info = pcall(vim.json.decode, content)
  if success then
    return theme_info
  else
    vim.notify("Failed to parse theme configuration", vim.log.levels.WARN)
    return nil
  end
end

function M.load_theme_config(colorscheme, variant)
  local theme_name = colorscheme .. "-" .. variant
  local config_file = theme_cache_dir .. "/" .. theme_name .. "/config.json"

  local file = io.open(config_file, "r")
  if not file then
    vim.notify("Theme config not found: " .. config_file, vim.log.levels.WARN)
    return nil
  end

  local content = file:read("*all")
  file:close()

  local success, theme_config = pcall(vim.json.decode, content)
  if success then
    return theme_config
  else
    vim.notify("Failed to parse theme config for " .. theme_name, vim.log.levels.WARN)
    return nil
  end
end

function M.get_neovim_colorscheme(theme_config)
  if not theme_config or not theme_config.appThemes then
    return nil
  end

  return theme_config.appThemes.neovim or theme_config.colorscheme
end

function M.apply_theme(colorscheme, variant)
  local theme_config = M.load_theme_config(colorscheme, variant)
  if not theme_config then
    return false
  end

  local nvim_colorscheme = M.get_neovim_colorscheme(theme_config)
  if not nvim_colorscheme then
    vim.notify(
      "No Neovim colorscheme found for " .. colorscheme .. "-" .. variant,
      vim.log.levels.WARN
    )
    return false
  end

  -- Apply the colorscheme
  local success, err = pcall(vim.cmd.colorscheme, nvim_colorscheme)
  if not success then
    vim.notify(
      "Failed to apply colorscheme '" .. nvim_colorscheme .. "': " .. err,
      vim.log.levels.ERROR
    )
    return false
  end

  -- Apply any custom highlights if defined
  if theme_config.customHighlights then
    for group, settings in pairs(theme_config.customHighlights) do
      vim.api.nvim_set_hl(0, group, settings)
    end
  end

  vim.notify("Theme applied: " .. colorscheme .. "-" .. variant, vim.log.levels.INFO)
  return true
end

function M.apply_current_theme()
  local theme_info = M.load_current_theme()
  if not theme_info then
    vim.notify("No current theme found", vim.log.levels.WARN)
    return false
  end

  return M.apply_theme(theme_info.colorscheme, theme_info.variant)
end

function M.setup_file_watcher()
  -- Create autocmd to watch for theme file changes
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = theme_state_file,
    callback = function()
      vim.schedule(function()
        M.apply_current_theme()
      end)
    end,
    desc = "Auto-reload theme when theme state changes",
  })

  -- Also set up a timer-based watcher as fallback
  local timer = vim.loop.new_timer()
  local last_mtime = 0

  timer:start(2000, 2000, function() -- Check every 2 seconds
    vim.loop.fs_stat(theme_state_file, function(err, stat)
      if not err and stat and stat.mtime.sec > last_mtime then
        last_mtime = stat.mtime.sec
        vim.schedule(function()
          M.apply_current_theme()
        end)
      end
    end)
  end)
end

function M.list_available_themes()
  local themes = {}
  local handle =
    io.popen("find " .. theme_cache_dir .. " -maxdepth 1 -type d -exec basename {} \\;")
  if handle then
    for theme in handle:lines() do
      if theme ~= "theme-cache" and theme ~= "" then
        table.insert(themes, theme)
      end
    end
    handle:close()
  end

  table.sort(themes)
  return themes
end

function M.switch_theme_interactive()
  local themes = M.list_available_themes()
  if #themes == 0 then
    vim.notify("No themes available", vim.log.levels.WARN)
    return
  end

  vim.ui.select(themes, {
    prompt = "Select theme:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      -- Use external theme switcher to change theme
      vim.system({ "sysinit-theme", "switch", choice }, {}, function(result)
        if result.code == 0 then
          vim.notify("Switched to theme: " .. choice, vim.log.levels.INFO)
        else
          vim.notify("Failed to switch theme: " .. choice, vim.log.levels.ERROR)
        end
      end)
    end
  end)
end

-- Expose commands
vim.api.nvim_create_user_command("ThemeSwitch", M.switch_theme_interactive, {
  desc = "Switch theme interactively",
})

vim.api.nvim_create_user_command("ThemeCurrent", function()
  local theme_info = M.load_current_theme()
  if theme_info then
    vim.notify(
      "Current theme: " .. theme_info.colorscheme .. "-" .. theme_info.variant,
      vim.log.levels.INFO
    )
  else
    vim.notify("No current theme found", vim.log.levels.WARN)
  end
end, {
  desc = "Show current theme",
})

vim.api.nvim_create_user_command("ThemeReload", M.apply_current_theme, {
  desc = "Reload current theme",
})

return M
