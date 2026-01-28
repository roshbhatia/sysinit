local styles = require("sysinit.plugins.ui.themes.styles")

local function convert_styles_for_nightfox(styles)
  local converted = {}
  for k, v in pairs(styles) do
    if type(v) == "table" and #v > 0 then
      converted[k] = table.concat(v, ",")
    elseif type(v) == "table" and #v == 0 then
      converted[k] = "NONE"
    else
      converted[k] = v
    end
  end
  return converted
end

return function()
  return {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = true,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = convert_styles_for_nightfox(styles),
      inverse = { match_paren = false, visual = false, search = false },
      modules = {
        cmp = true,
        dap_ui = true,
        fzf = true,
        gitsigns = true,
        hop = true,
        indent_blankline = true,
        native_lsp = { enabled = true, background = true },
        notify = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  }
end
