local json_loader = require("sysinit.utils.json_loader")
local theme_metadata = require("sysinit.plugins.ui.themes.metadata")
local overrides = require("sysinit.plugins.ui.themes.overrides")

local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local function setup_theme()
  local active_scheme = theme_config.colorscheme
  local plugin_config = theme_metadata[active_scheme]

  if not plugin_config then
    error("No theme config found for: " .. active_scheme)
  end

  -- Map theme names to config files
  local config_modules = {
    catppuccin = "sysinit.plugins.ui.themes.config.catppuccin",
    gruvbox = "sysinit.plugins.ui.themes.config.gruvbox",
    solarized = "sysinit.plugins.ui.themes.config.solarized",
    nord = "sysinit.plugins.ui.themes.config.nightfox",
    everforest = "sysinit.plugins.ui.themes.config.everforest",
    ["rose-pine"] = "sysinit.plugins.ui.themes.config.neomodern",
    kanagawa = "sysinit.plugins.ui.themes.config.kanso",
    tokyonight = "sysinit.plugins.ui.themes.config.tokyonight",
  }

  local config_module = config_modules[active_scheme]
  if config_module then
    local config_func = require(config_module)
    local config = config_func(theme_config)

    -- Themes that use vim.g variables don't need setup() call
    if plugin_config.setup == "everforest" or plugin_config.setup == "gruvbox-material" then
      -- Config already applied via vim.g variables in the config function
    else
      require(plugin_config.setup).setup(config)
    end
  end

  vim.cmd.colorscheme(plugin_config.colorscheme)
  overrides.apply(theme_config)

  vim.api.nvim_create_autocmd({ "ColorScheme", "CmdLineEnter" }, {
    pattern = plugin_config.colorscheme,
    callback = function()
      overrides.apply(theme_config)
    end,
  })
end

local function build_plugins()
  local scheme = theme_config.colorscheme
  local metadata = theme_metadata[scheme]

  if not metadata then
    error("Unknown theme: " .. scheme)
  end

  return {
    {
      metadata.plugin,
      lazy = false,
      priority = 1000,
      config = setup_theme,
    },
  }
end

return build_plugins()
