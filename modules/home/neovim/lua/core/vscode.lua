local M = {}

function M.setup()
  -- Only run this code if we're in VSCode
  if not vim.g.vscode then
    return
  end
  

  -- Basic navigation keybindings - make hjkl work like normal within VSCode
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  
  -- Define VSCode command wrapper function
  local function vscode_command(command)
    return function()
      vim.fn.VSCodeNotify(command)
    end
  end
  
  -- Special handling for neoscroll in VSCode
  local status, neoscroll = pcall(require, "neoscroll")
  if status then
    -- Make sure neoscroll uses VSCode-friendly settings
    neoscroll.setup({
      hide_cursor = false,         -- Don't hide cursor in VSCode
      performance_mode = false,    -- VSCode handles this itself
      easing = 'linear',           -- Simpler easing for VSCode
      cursor_scrolls_alone = true, 
      mappings = {                 -- Keep the same mappings
        '<C-u>', '<C-d>',
        '<C-b>', '<C-f>',
        '<C-y>', '<C-e>',
        'zt', 'zz', 'zb',
      },
    })
  end

  -- Navigation
  vim.keymap.set('n', 'gd', vscode_command('editor.action.revealDefinition'), { silent = true, desc = "Go to Definition" })
  vim.keymap.set('n', 'gr', vscode_command('editor.action.goToReferences'), { silent = true, desc = "Go to References" })
  vim.keymap.set('n', 'gi', vscode_command('editor.action.goToImplementation'), { silent = true, desc = "Go to Implementation" })
  vim.keymap.set('n', 'gt', vscode_command('editor.action.goToTypeDefinition'), { silent = true, desc = "Go to Type Definition" })
  
  -- UI Elements
  vim.keymap.set('n', '<leader>e', vscode_command('workbench.view.explorer'), { silent = true, desc = "Explorer" })
  vim.keymap.set('n', '<leader>f', vscode_command('workbench.action.quickOpen'), { silent = true, desc = "Find Files" })
  vim.keymap.set('n', '<leader>b', vscode_command('workbench.action.showAllEditors'), { silent = true, desc = "Show All Editors" })
  
  -- Editing
  vim.keymap.set('n', '<leader>ca', vscode_command('editor.action.quickFix'), { silent = true, desc = "Code Actions" })
  vim.keymap.set('n', '<leader>rn', vscode_command('editor.action.rename'), { silent = true, desc = "Rename" })
  vim.keymap.set('n', '<leader>cf', vscode_command('editor.action.formatDocument'), { silent = true, desc = "Format Document" })
  
  -- Comment toggle (using VSCode's built-in comment toggling)
  vim.keymap.set('n', 'gcc', vscode_command('editor.action.commentLine'), { silent = true, desc = "Toggle Comment" })
  vim.keymap.set('v', 'gc', vscode_command('editor.action.commentLine'), { silent = true, desc = "Toggle Comment" })
  
  -- Search
  vim.keymap.set('n', '<leader>s', vscode_command('actions.find'), { silent = true, desc = "Search in File" })
  vim.keymap.set('n', '<leader>fg', vscode_command('workbench.action.findInFiles'), { silent = true, desc = "Find in Files" })
  
  -- Terminal
  vim.keymap.set('n', '<leader>tt', vscode_command('workbench.action.terminal.toggleTerminal'), { silent = true, desc = "Toggle Terminal" })
  
  -- Git
  vim.keymap.set('n', '<leader>gs', vscode_command('workbench.view.scm'), { silent = true, desc = "Source Control" })
  vim.keymap.set('n', '<leader>gb', vscode_command('gitlens.toggleFileBlame'), { silent = true, desc = "Toggle Git Blame" })
  
  -- Hover documentation
  vim.keymap.set('n', 'K', vscode_command('editor.action.showHover'), { silent = true, desc = "Show Hover" })
  
  -- Extensions
  vim.keymap.set('n', '<leader>x', vscode_command('workbench.view.extensions'), { silent = true, desc = "Extensions" })
  
  -- File operations
  vim.keymap.set('n', '<leader>w', vscode_command('workbench.action.files.save'), { silent = true, desc = "Save File" })
  vim.keymap.set('n', '<leader>q', vscode_command('workbench.action.closeActiveEditor'), { silent = true, desc = "Close Editor" })
  
  -- Panels/Sidebar
  vim.keymap.set('n', '<leader>ue', vscode_command('workbench.action.toggleSidebarVisibility'), { silent = true, desc = "Toggle Sidebar" })
  vim.keymap.set('n', '<leader>ut', vscode_command('workbench.action.togglePanel'), { silent = true, desc = "Toggle Panel" })
  
  -- Import vscode-specific parts from the VSCode Neovim config if available
  local status, vscode_keys = pcall(require, "vscode.mappings")
  if status then
    vscode_keys.setup()
  end
  
  -- Add custom VSCode-only autocommands
  vim.api.nvim_create_augroup("VSCodeGroup", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "VSCodeInitialized",
    group = "VSCodeGroup",
    callback = function()
      -- Any initialization that needs to happen after VSCode is fully initialized
      print("VSCode Neovim integration initialized")
    end,
  })
end

return M
