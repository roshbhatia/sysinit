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
  
  -- Map keys to Jumpy2 extension commands
  -- We'll set them up similar to hop.nvim for consistency
  
  -- Character motions using Jumpy2
  vim.keymap.set({"n","v","o"}, "f", function()
    vscode.action("jumpy2.toggle")
  end, { desc = "Jumpy2 Jump Mode" })
  
  vim.keymap.set({"n","v","o"}, "F", function()
    vscode.action("jumpy2.toggleSelection")
  end, { desc = "Jumpy2 Selection Mode" })
  
  -- Leader based motions (similar to hop)
  vim.keymap.set("n", "<leader>hw", function()
    vscode.action("jumpy2.toggle")
  end, { desc = "Jumpy2 Word Jump" })
  
  -- For line mode, we'll use the same binding though Jumpy2 doesn't have a specific line mode
  vim.keymap.set("n", "<leader>hl", function()
    vscode.action("jumpy2.toggle")
  end, { desc = "Jumpy2 Jump Mode" })
  
  vim.keymap.set("n", "<leader>ha", function()
    vscode.action("jumpy2.toggle")
  end, { desc = "Jumpy2 Jump Anywhere" })
  
  -- Exit jumpy mode with Escape
  vim.keymap.set("n", "<Esc>", function()
    vscode.action("jumpy2.exit")
  end, { desc = "Exit Jumpy2 Mode" })
  
  -- Reset first character in Jumpy2 mode with Backspace
  vim.keymap.set("n", "<BS>", function()
    vscode.action("jumpy2.reset")
  end, { desc = "Reset Jumpy2 Character" })
  
  -- Add help text to which-key if available
  local which_key_ok, which_key = pcall(require, "modules.vscode.vsc-which-key")
  if which_key_ok and which_key.keybindings then
    -- Create a new section for jumpy if it doesn't exist already
    if not which_key.keybindings.h then
      which_key.keybindings.h = {
        name = "🦘 Jumpy2",
        bindings = {}
      }
    end
    
    -- Add/update jumpy bindings
    table.insert(which_key.keybindings.h.bindings, 
      { key = "w", description = "Jumpy2 Word Jump", action = "jumpy2.toggle" })
    table.insert(which_key.keybindings.h.bindings, 
      { key = "l", description = "Jumpy2 Jump Mode", action = "jumpy2.toggle" })
    table.insert(which_key.keybindings.h.bindings, 
      { key = "a", description = "Jumpy2 Jump Anywhere", action = "jumpy2.toggle" })
  end
  
  -- Add navigation bindings like in the docs
  vim.keymap.set("n", "<BS>", function()
    vscode.action("workbench.action.navigateBack")
  end, { desc = "Navigate Back", 
        when = "editorTextFocus && vim.active && !inDebugRepl && vim.mode == 'Normal'" })
  
  vim.keymap.set("n", "<S-BS>", function()
    vscode.action("workbench.action.navigateForward")
  end, { desc = "Navigate Forward", 
        when = "editorTextFocus && vim.active && !inDebugRepl && vim.mode == 'Normal'" })
  
  -- Notify user about Jumpy2 extension
  vim.notify([[
    Using Jumpy2 extension for VSCode.
    Make sure you have it installed: https://marketplace.visualstudio.com/items?itemName=davidlgoldberg.jumpy2
    
    You may need to add these keybindings to your VSCode keybindings.json:
    {
        "key": "f",
        "command": "jumpy2.toggle",
        "when": "editorTextFocus && neovim.mode == 'normal'"
    },
    {
        "key": "F",
        "command": "jumpy2.toggleSelection",
        "when": "editorTextFocus && neovim.mode == 'normal'"
    },
    {
        "key": "escape",
        "command": "jumpy2.exit",
        "when": "editorTextFocus && jumpy2.jump-mode"
    },
    {
        "key": "backspace",
        "command": "jumpy2.reset",
        "when": "jumpy2.jump-mode && editorTextFocus"
    },
    {
        "key": "backspace",
        "command": "workbench.action.navigateBack",
        "when": "editorTextFocus && vim.active && !inDebugRepl && vim.mode == 'Normal'"
    },
    {
        "key": "shift+backspace",
        "command": "workbench.action.navigateForward",
        "when": "editorTextFocus && vim.active && !inDebugRepl && vim.mode == 'Normal'"
    }
  ]], vim.log.levels.INFO)
end

return M