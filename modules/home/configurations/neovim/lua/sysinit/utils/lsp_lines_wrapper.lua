---@mod sysinit.utils.lsp_lines_wrapper LSP Lines error handling wrapper
---@brief [[
--- This module provides error handling wrapper for lsp_lines.nvim to prevent
--- "Invalid buffer id" errors from hanging the UI by using vim.notify instead.
---@brief ]]

local M = {}

--- Wrap lsp_lines functions to handle buffer errors gracefully
function M.setup()
  local lsp_lines = require("lsp_lines")
  local original_hide = lsp_lines.hide
  local original_show = lsp_lines.show

  -- Override hide function to catch buffer errors and use notify
  lsp_lines.hide = function()
    local ok, err = pcall(original_hide)
    if not ok and err and err:match("Invalid buffer id") then
      vim.notify("LSP Lines: Buffer no longer exists", vim.log.levels.WARN)
    elseif not ok then
      vim.notify("LSP Lines error: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  -- Override show function to catch buffer errors and use notify
  lsp_lines.show = function()
    local ok, err = pcall(original_show)
    if not ok and err and err:match("Invalid buffer id") then
      vim.notify("LSP Lines: Buffer no longer exists", vim.log.levels.WARN)
    elseif not ok then
      vim.notify("LSP Lines error: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  lsp_lines.setup()
end

return M
