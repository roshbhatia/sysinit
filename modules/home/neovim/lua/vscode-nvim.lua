-- VSCode integration utilities
local M = {}

-- VSCode command wrapper function
function M.command(cmd)
  return function()
    if vim.fn.exists('*VSCodeNotify') == 1 then
      vim.fn.VSCodeNotify(cmd)
    elseif vim.fn.exists('*vscode.call') == 1 then
      vim.fn.vscode.call(cmd)
    elseif vim.g.vscode then
      -- Fallback method for older versions
      vim.cmd('call VSCodeCall("' .. cmd .. '")')
    end
  end
end

-- VSCode extensions command
function M.ext_command(extension, cmd)
  return function()
    local full_command = extension .. '.' .. cmd
    if vim.fn.exists('*VSCodeExtensionNotify') == 1 then
      vim.fn.VSCodeExtensionNotify(extension, cmd)
    else
      M.command(full_command)()
    end
  end
end

-- Set up VSCode-specific keybindings
function M.setup_keymaps()
  local opts = { noremap = true, silent = true }
  
  -- Navigation (move through wrapped lines)
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  
  -- Window navigation
  vim.keymap.set("n", "<C-h>", M.command("workbench.action.navigateLeft"), opts)
  vim.keymap.set("n", "<C-j>", M.command("workbench.action.navigateDown"), opts)
  vim.keymap.set("n", "<C-k>", M.command("workbench.action.navigateUp"), opts)
  vim.keymap.set("n", "<C-l>", M.command("workbench.action.navigateRight"), opts)
  
  -- Window management
  vim.keymap.set('n', '<C-w>v', M.command('workbench.action.splitEditorRight'), opts)
  vim.keymap.set('n', '<C-w>s', M.command('workbench.action.splitEditorDown'), opts)
  vim.keymap.set('n', '<C-w>q', M.command('workbench.action.closeActiveEditor'), opts)
  vim.keymap.set('n', '<C-w>=', M.command('workbench.action.evenEditorWidths'), opts)
  vim.keymap.set('n', '<C-w>_', M.command('workbench.action.toggleEditorWidths'), opts)
  
  -- LSP-like operations (modified to avoid overlaps)
  vim.keymap.set('n', '<leader>gd', M.command('editor.action.revealDefinition'), opts)
  vim.keymap.set('n', '<leader>gr', M.command('editor.action.goToReferences'), opts)
  vim.keymap.set('n', '<leader>gi', M.command('editor.action.goToImplementation'), opts)
  vim.keymap.set('n', '<leader>gt', M.command('editor.action.goToTypeDefinition'), opts)
  vim.keymap.set('n', 'K', M.command('editor.action.showHover'), opts)
  
  -- Code actions
  vim.keymap.set('n', '<leader>ca', M.command('editor.action.quickFix'), opts)
  vim.keymap.set('n', '<leader>rn', M.command('editor.action.rename'), opts)
  vim.keymap.set('n', '<leader>cf', M.command('editor.action.formatDocument'), opts)
  
  -- Comments (modified to avoid overlaps)
  vim.keymap.set('n', '<leader>/', M.command('editor.action.commentLine'), opts)
  vim.keymap.set('v', '<leader>/', M.command('editor.action.commentLine'), opts)
  
  -- File/project operations
  vim.keymap.set('n', '<leader>ff', M.command('search-preview.quickOpenWithPreview'), opts)
  vim.keymap.set('n', '<leader>fg', M.command('workbench.action.findInFiles'), opts)
  vim.keymap.set('n', '<leader>fs', M.command('actions.find'), opts)
  vim.keymap.set('n', '<leader>e', M.command('workbench.view.explorer'), opts)
  vim.keymap.set('n', '<leader>w', M.command('workbench.action.files.save'), opts)
  vim.keymap.set('n', '<leader>q', M.command('workbench.action.closeActiveEditor'), opts)
  
  -- Terminal
  vim.keymap.set('n', '<leader>tt', M.command('workbench.action.terminal.toggleTerminal'), opts)
  
  -- UI toggles
  vim.keymap.set('n', '<leader>ue', M.command('workbench.action.toggleSidebarVisibility'), opts)
  vim.keymap.set('n', '<leader>ut', M.command('workbench.action.togglePanel'), opts)
  vim.keymap.set('n', '<leader>uf', M.command('workbench.action.toggleFullScreen'), opts)
  
  -- Git
  vim.keymap.set('n', '<leader>gs', M.command('workbench.view.scm'), opts)
  vim.keymap.set('n', '<leader>gb', M.command('gitlens.toggleFileBlame'), opts)
  vim.keymap.set('n', '<leader>gc', M.command('git.commitAll'), opts)
  vim.keymap.set('n', '<leader>gp', M.command('git.push'), opts)
  
  -- Session management (workspaces in VSCode)
  vim.keymap.set('n', '<leader>ss', M.command('workbench.action.files.saveWorkspaceAs'), opts)
  vim.keymap.set('n', '<leader>sl', M.command('workbench.action.openRecent'), opts)
  vim.keymap.set('n', '<leader>sd', M.command('workbench.action.closeFolder'), opts)
  
  -- Development tools
  vim.keymap.set('n', '<leader>dc', M.command('workbench.panel.chat.view.copilot.focus'), opts)
  vim.keymap.set('n', '<leader>di', M.command('inlineChat.start'), opts)
  
  -- Keep cursor centered (pure Neovim)
  vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
  vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
  vim.keymap.set('n', 'n', 'nzzzv', opts)
  vim.keymap.set('n', 'N', 'Nzzzv', opts)
  
  -- Quick escape
  vim.keymap.set('n', '<Esc><Esc>', M.command('workbench.action.focusActiveEditorGroup'), opts)
end

-- Configure VSCode-compatible plugins
function M.configure_plugins()
  -- Neoscroll settings for VSCode
  local status, neoscroll = pcall(require, "neoscroll")
  if status then
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
  
  -- AutoSession for VSCode (minimal config)
  local session_status, auto_session = pcall(require, "auto-session")
  if session_status then
    auto_session.setup({
      auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      log_level = "error",
      auto_session_enable_last_session = false,
      auto_save_enabled = false,  -- Let VSCode handle this
      auto_restore_enabled = false, -- Let VSCode handle this
      bypass_save_filetypes = { "alpha", "NvimTree", "dashboard", "neo-tree" },
    })
  end
end

-- Initialize VSCode integration
function M.setup()
  if not vim.g.vscode then
    return
  end

  -- Add initialization message
  vim.notify("VSCode Neovim integration initializing...", vim.log.levels.INFO)
  
  -- Set up VSCode-specific keybindings
  M.setup_keymaps()
  
  -- Configure plugins for VSCode compatibility
  M.configure_plugins()
  
  -- Register VSCode initialization event
  vim.api.nvim_create_augroup("VSCodeGroup", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "VSCodeInitialized",
    group = "VSCodeGroup",
    callback = function()
      vim.notify("VSCode Neovim integration initialized", vim.log.levels.INFO)
    end,
  })
end

return M
