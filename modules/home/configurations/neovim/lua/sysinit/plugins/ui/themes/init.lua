local json_loader = require("sysinit.utils.json_loader")
local theme_metadata = require("sysinit.plugins.ui.themes.metadata")
local overrides = require("sysinit.plugins.ui.themes.overrides")

local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local function setup_theme()
  local active_scheme = theme_config and theme_config.colorscheme
  local plugin_config = theme_metadata[active_scheme]

  local config_modules = {
    catppuccin = "sysinit.plugins.ui.themes.config.catppuccin",
    gruvbox = "sysinit.plugins.ui.themes.config.gruvbox",
    everforest = "sysinit.plugins.ui.themes.config.everforest",
    ["rose-pine"] = "sysinit.plugins.ui.themes.config.neomodern",
  }

  local config_module = config_modules[active_scheme]
  if config_module then
    local config_func = require(config_module)
    local config = config_func(theme_config)

    if not (plugin_config.setup == "everforest" or plugin_config.setup == "gruvbox-material") then
      require(plugin_config.setup).setup(config)
    end
  end

  vim.cmd.colorscheme(plugin_config.colorscheme)
  overrides.apply(theme_config)

  ---@diagnostic disable-next-line: assign-type-mismatch
  vim.api.nvim_create_autocmd({ "ColorScheme", "CmdLineEnter" }, {
    pattern = plugin_config.colorscheme,
    callback = function()
      overrides.apply(theme_config)
    end,
  })
end

local function build_plugins()
  local scheme = theme_config and theme_config.colorscheme
  local metadata = theme_metadata[scheme]

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
