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
  
  -- Map keys to Jumpy extension commands
  -- Since Jumpy doesn't come with default keybindings, we'll set them up
  -- similar to hop.nvim for consistency
  
  -- Character motions using Jumpy Word Mode
  vim.keymap.set({"n","v","o"}, "f", function()
    vscode.action("extension.jumpy-word")
  end, { desc = "Jumpy Word Mode" })
  
  -- Leader based motions
  vim.keymap.set("n", "<leader>hw", function()
    vscode.action("extension.jumpy-word")
  end, { desc = "Jumpy Word Mode" })
  
  vim.keymap.set("n", "<leader>hl", function()
    vscode.action("extension.jumpy-line")
  end, { desc = "Jumpy Line Mode" })
  
  -- Exit jumpy mode with <Esc>
  vim.keymap.set("n", "<Esc>", function()
    vscode.action("extension.jumpy-exit")
  end, { desc = "Exit Jumpy Mode" })
  
  -- Add help text to which-key if available
  local which_key_ok, which_key = pcall(require, "modules.vscode.vsc-which-key")
  if which_key_ok and which_key.keybindings then
    -- Create a new section for jumpy if it doesn't exist already
    if not which_key.keybindings.h then
      which_key.keybindings.h = {
        name = "🦘 Jumpy",
        bindings = {}
      }
    end
    
    -- Add/update jumpy bindings
    table.insert(which_key.keybindings.h.bindings, 
      { key = "w", description = "Jumpy Word Mode", action = "extension.jumpy-word" })
    table.insert(which_key.keybindings.h.bindings, 
      { key = "l", description = "Jumpy Line Mode", action = "extension.jumpy-line" })
  end
  
  -- Notify user about Jumpy extension
  vim.notify([[
    Using Jumpy extension for VSCode.
    Make sure you have it installed: https://marketplace.visualstudio.com/items?itemName=wmaurer.vscode-jumpy
    
    You may need to add these keybindings to your VSCode keybindings.json:
    {
        "key": "f",
        "command": "extension.jumpy-word",
        "when": "editorTextFocus && neovim.mode == 'normal'"
    },
    {
        "key": "Escape",
        "command": "extension.jumpy-exit",
        "when": "editorTextFocus && jumpy.isJumpyMode"
    }
  ]], vim.log.levels.INFO)
end

return M