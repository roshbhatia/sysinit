-- Disable treesitter highlighting for markdown, use LSP instead
vim.b.ts_highlight = false
if vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then
  vim.treesitter.stop(vim.api.nvim_get_current_buf())
end

Snacks.keymap.set("n", "<localleader>xp", function()
  local file = vim.fn.expand("%:p")
  Snacks.terminal.toggle({ "glow", "-p", file }, {
    win = { position = "right", width = 0.4 },
  })
end, { ft = "markdown", desc = "Preview with glow" })

-- Enable LSP semantic tokens for markdown
vim.b.semantic_tokens = true

-- Use traditional regex highlighting as fallback
vim.bo.syntax = "on"

-- markdown_oxide: only enable if .obsidian folder exists in workspace root
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
