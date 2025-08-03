local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

local transparency_enabled = theme_config.transparency.enable

local theme_modules = {
  catppuccin = require("sysinit.themes.catppuccin"),
  gruvbox = require("sysinit.themes.gruvbox"),
  kanagawa = require("sysinit.themes.kanagawa"),
  ["rose-pine"] = require("sysinit.themes.rose_pine"),
  solarized = require("sysinit.themes.solarized"),
  nord = require("sysinit.themes.nord"),
}

local function get_transparent_highlights()
  local theme_module = theme_modules[theme_config.colorscheme]
  if theme_module and theme_module.get_transparent_highlights then
    return theme_module.get_transparent_highlights()
  end
  return {}
end

local function apply_transparency(enable)
  local plugin_config = theme_config.plugins[theme_config.colorscheme][theme_config.variant]
  local theme_module = theme_modules[theme_config.colorscheme]

  if enable then
    local highlights = get_transparent_highlights()
    for group, opts in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, opts)
    end
  else
    if theme_module and theme_module.setup then
      theme_module.setup({ transparent_background = false, show_end_of_buffer = true })
    end
    vim.cmd("colorscheme " .. plugin_config.colorscheme)
  end

  transparency_enabled = enable
end

local function toggle_transparency()
  apply_transparency(not transparency_enabled)

  local status = transparency_enabled and "enabled" or "disabled"
  vim.notify("Transparency " .. status, vim.log.levels.INFO)
end

function M.setup()
  vim.keymap.set({ "n", "i", "v", "t" }, "<C-A-t>", toggle_transparency, {
    noremap = true,
    silent = true,
    desc = "Toggle transparency",
  })

  vim.keymap.set({ "n", "i", "v", "t" }, "<F24>", function()
    apply_transparency(true)
  end, {
    noremap = true,
    silent = true,
    desc = "Enable transparency (from WezTerm)",
  })

  vim.keymap.set({ "n", "i", "v", "t" }, "<F23>", function()
    apply_transparency(false)
  end, {
    noremap = true,
    silent = true,
    desc = "Disable transparency (from WezTerm)",
  })
end

return M
