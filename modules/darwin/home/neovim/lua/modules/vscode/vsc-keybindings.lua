local M = {}

M.plugins = {}

function M.setup()
  if not vim.g.vscode then return end
  
  local vscode_ok, vscode = pcall(require, "vscode")
  if not vscode_ok then
    vim.notify("VSCode module not available", vim.log.levels.ERROR)
    return
  end
  
  local opts = { noremap = true, silent = true }
  
  -- Window navigation
  vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
  vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
  vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
  vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)
  
  -- Code navigation
  vim.keymap.set("n", "gd", function() vscode.action("editor.action.revealDefinition") end, opts)
  vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end, opts)
  vim.keymap.set("n", "gi", function() vscode.action("editor.action.goToImplementation") end, opts)
  vim.keymap.set("n", "K", function() vscode.action("editor.action.showHover") end, opts)
  
  -- Comments
  vim.keymap.set("n", "gcc", function() vscode.action("editor.action.commentLine") end, opts)
  vim.keymap.set("v", "gc", function() vscode.action("editor.action.commentLine") end, opts)
  
  -- Return to editor / escape terminal
  vim.keymap.set("n", "<Esc><Esc>", function() vscode.action("workbench.action.focusActiveEditorGroup") end, opts)
  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts)
  
  -- Better scrolling
  vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
  vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
  vim.keymap.set("n", "n", "nzzzv", opts)
  vim.keymap.set("n", "N", "Nzzzv", opts)
end

return M