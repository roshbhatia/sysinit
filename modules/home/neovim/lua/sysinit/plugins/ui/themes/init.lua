local json_loader = require("sysinit.utils.json_loader")
local theme_metadata = require("sysinit.plugins.ui.themes.metadata")
local overrides = require("sysinit.plugins.ui.themes.overrides")

local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local function setup_theme()
  local active_scheme = theme_config and theme_config.colorscheme or "nord"
  local plugin_config = theme_metadata[active_scheme]

  if not plugin_config then
    active_scheme = "nord"
    plugin_config = theme_metadata[active_scheme]
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
    flexoki = "sysinit.plugins.ui.themes.config.flexoki",
    ["apple-system-colors"] = "sysinit.plugins.ui.themes.config.apple-system-colors",
  }

  local config_module = config_modules[active_scheme]
  if config_module then
    local config_func = require(config_module)
    local config = config_func(theme_config)

    -- base16-nvim themes use setup() with color table directly
    if plugin_config.setup == "base16-colorscheme" then
      require(plugin_config.setup).setup(config)
    -- Themes that use vim.g variables don't need setup() call
    elseif plugin_config.setup == "everforest" or plugin_config.setup == "gruvbox-material" then
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
  local scheme = theme_config and theme_config.colorscheme or "nord"
  local metadata = theme_metadata[scheme]

  if not metadata then
    scheme = "nord"
    metadata = theme_metadata[scheme]
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
