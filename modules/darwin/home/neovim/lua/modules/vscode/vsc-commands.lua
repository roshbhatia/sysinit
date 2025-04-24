local M = {}

M.plugins = {}

-- Command mapping for VSCode commands
M.cmd_map = {
  w      = "workbench.action.files.save",
  wa     = "workbench.action.files.saveAll",
  q      = "workbench.action.closeActiveEditor",
  qa     = "workbench.action.quit",
  enew   = "workbench.action.files.newUntitledFile",
  bdelete= "workbench.action.closeActiveEditor",
  bn     = "workbench.action.nextEditor",
  bp     = "workbench.action.previousEditor",
  split  = "workbench.action.splitEditorDown",
  vsplit = "workbench.action.splitEditorRight",
}

function M.setup()
  if not vim.g.vscode then return end
  
  local vscode_ok, vscode = pcall(require, "vscode")
  if not vscode_ok then
    vim.notify("VSCode module not available", vim.log.levels.ERROR)
    return
  end
  
  -- Map Vim commands to VSCode actions
  local function map_cmd(mode, lhs, cmd, opts)
    opts = opts or { noremap = true, silent = true }
    local action = M.cmd_map[cmd]
    if action then
      vim.keymap.set(mode, lhs, function() vscode.action(action) end, opts)
    else
      vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
    end
  end
  
  -- Common commands
  local opts = { noremap = true, silent = true }
  map_cmd("n", "<leader>w", "w", opts)
  map_cmd("n", "<leader>wa", "wa", opts)
  
  -- Splits
  map_cmd("n", "<leader>\\\\", "vsplit", opts)
  map_cmd("n", "<leader>-", "split", opts)
  
  -- Register the map_cmd function so other modules can use it
  M.map_cmd = map_cmd
end

return M