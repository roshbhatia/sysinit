-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/vscode-neovim/vscode-neovim/refs/heads/master/README.md"
local M = {}

M.plugins = {
  {
    "asvetliakov/vscode-neovim",
    -- This plugin is only active when in VSCode
    cond = function()
      return vim.g.vscode == true
    end,
    config = function()
      -- Set up keymaps and configurations
      local opts = { noremap = true, silent = true }
      
      -- Navigation (move through wrapped lines)
      vim.keymap.set('n', 'j', 'gj', { silent = true })
      vim.keymap.set('n', 'k', 'gk', { silent = true })
      
      -- VSCode command wrapper function
      local function cmd(command)
        return function()
          if vim.fn.exists('*VSCodeNotify') == 1 then
            vim.fn.VSCodeNotify(command)
          elseif vim.fn.exists('*vscode.call') == 1 then
            vim.fn.vscode.call(command)
          elseif vim.g.vscode then
            -- Fallback method for older versions
            vim.cmd('call VSCodeCall("' .. command .. '")')
          end
        end
      end
      
      -- Window navigation
      vim.keymap.set("n", "<C-h>", cmd("workbench.action.navigateLeft"), opts)
      vim.keymap.set("n", "<C-j>", cmd("workbench.action.navigateDown"), opts)
      vim.keymap.set("n", "<C-k>", cmd("workbench.action.navigateUp"), opts)
      vim.keymap.set("n", "<C-l>", cmd("workbench.action.navigateRight"), opts)
      
      -- Window management
      vim.keymap.set('n', '<C-w>v', cmd('workbench.action.splitEditorRight'), opts)
      vim.keymap.set('n', '<C-w>s', cmd('workbench.action.splitEditorDown'), opts)
      vim.keymap.set('n', '<C-w>q', cmd('workbench.action.closeActiveEditor'), opts)
      vim.keymap.set('n', '<C-w>=', cmd('workbench.action.evenEditorWidths'), opts)
      vim.keymap.set('n', '<C-w>_', cmd('workbench.action.toggleEditorWidths'), opts)
      
      -- LSP-like operations (modified to avoid overlaps)
      vim.keymap.set('n', '<leader>gd', cmd('editor.action.revealDefinition'), opts)
      vim.keymap.set('n', '<leader>gr', cmd('editor.action.goToReferences'), opts)
      vim.keymap.set('n', '<leader>gi', cmd('editor.action.goToImplementation'), opts)
      vim.keymap.set('n', '<leader>gt', cmd('editor.action.goToTypeDefinition'), opts)
      vim.keymap.set('n', 'K', cmd('editor.action.showHover'), opts)
      
      -- Code actions
      vim.keymap.set('n', '<leader>ca', cmd('editor.action.quickFix'), opts)
      vim.keymap.set('n', '<leader>rn', cmd('editor.action.rename'), opts)
      vim.keymap.set('n', '<leader>cf', cmd('editor.action.formatDocument'), opts)
      
      -- Comments
      vim.keymap.set('n', '<leader>/', cmd('editor.action.commentLine'), opts)
      vim.keymap.set('v', '<leader>/', cmd('editor.action.commentLine'), opts)
      
      -- File/project operations
      vim.keymap.set('n', '<leader>ff', cmd('search-preview.quickOpenWithPreview'), opts)
      vim.keymap.set('n', '<leader>fg', cmd('workbench.action.findInFiles'), opts)
      vim.keymap.set('n', '<leader>fs', cmd('actions.find'), opts)
      vim.keymap.set('n', '<leader>e', cmd('workbench.view.explorer'), opts)
      vim.keymap.set('n', '<leader>w', cmd('workbench.action.files.save'), opts)
      vim.keymap.set('n', '<leader>q', cmd('workbench.action.closeActiveEditor'), opts)
      
      -- Terminal
      vim.keymap.set('n', '<leader>tt', cmd('workbench.action.terminal.toggleTerminal'), opts)
      
      -- UI toggles
      vim.keymap.set('n', '<leader>ue', cmd('workbench.action.toggleSidebarVisibility'), opts)
      vim.keymap.set('n', '<leader>ut', cmd('workbench.action.togglePanel'), opts)
      vim.keymap.set('n', '<leader>uf', cmd('workbench.action.toggleFullScreen'), opts)
      
      -- Git
      vim.keymap.set('n', '<leader>gs', cmd('workbench.view.scm'), opts)
      vim.keymap.set('n', '<leader>gb', cmd('gitlens.toggleFileBlame'), opts)
      vim.keymap.set('n', '<leader>gc', cmd('git.commitAll'), opts)
      vim.keymap.set('n', '<leader>gp', cmd('git.push'), opts)
      
      -- Session management (workspaces in VSCode)
      vim.keymap.set('n', '<leader>ss', cmd('workbench.action.files.saveWorkspaceAs'), opts)
      vim.keymap.set('n', '<leader>sl', cmd('workbench.action.openRecent'), opts)
      vim.keymap.set('n', '<leader>sd', cmd('workbench.action.closeFolder'), opts)
      
      -- Development tools
      vim.keymap.set('n', '<leader>dc', cmd('workbench.panel.chat.view.copilot.focus'), opts)
      vim.keymap.set('n', '<leader>di', cmd('inlineChat.start'), opts)
      
      -- Keep cursor centered (pure Neovim)
      vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
      vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
      vim.keymap.set('n', 'n', 'nzzzv', opts)
      vim.keymap.set('n', 'N', 'Nzzzv', opts)
      
      -- Quick escape
      vim.keymap.set('n', '<Esc><Esc>', cmd('workbench.action.focusActiveEditorGroup'), opts)
      
      -- Register VSCode initialization event
      vim.api.nvim_create_augroup("VSCodeGroup", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = "VSCodeInitialized",
        group = "VSCodeGroup",
        callback = function()
          vim.notify("VSCode Neovim integration initialized", vim.log.levels.INFO)
        end,
      })

      -- Notify of initialization
      vim.notify("VSCode Neovim integration loaded", vim.log.levels.INFO)
    end
  }
}

-- For modules like neoscroll and others that need specific VSCode configuration
function M.setup_compat_plugins()
  if not vim.g.vscode then
    return
  end
  
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

return M
