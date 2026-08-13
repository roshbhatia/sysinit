vim.b.ts_highlight = false
if vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then
  vim.treesitter.stop(vim.api.nvim_get_current_buf())
end

Snacks.keymap.set("n", "<localleader>xp", function()
  require("utils.markdown_preview").toggle_glow()
end, { ft = "markdown", desc = "Preview with glow" })

Snacks.keymap.set("n", "<localleader>xP", function()
  require("utils.markdown_preview").toggle_browser()
end, { ft = "markdown", desc = "Preview in browser (go-grip)" })

vim.b.semantic_tokens = true

vim.bo.syntax = "on"

local function has_obsidian_workspace()
  return vim.fn.isdirectory(vim.fn.getcwd() .. "/.obsidian") == 1
end

if has_obsidian_workspace() then
  local capabilities = vim.tbl_deep_extend("force", require("blink.cmp").get_lsp_capabilities(), {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  })

  vim.lsp.config("markdown_oxide", {
    cmd = { "markdown-oxide" },
    root_markers = { ".obsidian" },
    capabilities = capabilities,
  })
  vim.lsp.enable({ "markdown_oxide" })
end
