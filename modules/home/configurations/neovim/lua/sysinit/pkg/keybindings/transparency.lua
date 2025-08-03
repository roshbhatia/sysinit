local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

local transparency_enabled = theme_config.transparency.enable

local function get_transparent_highlights()
  local highlights = {}

  if theme_config.colorscheme == "kanagawa" then
    highlights = {
      Normal = { bg = "none" },
      NormalNC = { bg = "none" },
      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },
      Pmenu = { bg = "none" },
      TelescopeNormal = { bg = "none" },
      TelescopeBorder = { bg = "none" },
      SignColumn = { bg = "none" },
      CursorLine = { bg = "none" },
      StatusLine = { bg = "none" },
      StatusLineNC = { bg = "none" },
      WinSeparator = { bg = "none" },
      NeoTreeNormal = { bg = "none" },
      NeoTreeNormalNC = { bg = "none" },
      NeoTreeWinSeparator = { bg = "none" },
      WinBar = { bg = "none" },
      WinBarNC = { bg = "none" },
    }
  end

  return highlights
end

local function apply_transparency(enable)
  local plugin_config = theme_config.plugins[theme_config.colorscheme][theme_config.variant]

  if enable then
    local highlights = get_transparent_highlights()
    for group, opts in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, opts)
    end
  else
    if theme_config.colorscheme == "kanagawa" then
      local kanagawa = require("kanagawa")
      kanagawa.setup({ transparent = false })
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
