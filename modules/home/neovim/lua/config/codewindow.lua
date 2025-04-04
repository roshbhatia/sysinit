-- Check if code preview should be enabled
if vim.g.code_preview_enabled == nil then
    vim.g.code_preview_enabled = false -- default to false (hidden when no file open)
end

-- Safely setup codewindow - it requires treesitter
local ok, treesitter = pcall(require, 'nvim-treesitter')
if not ok then
    vim.notify("Treesitter not available, codewindow minimap will be disabled", vim.log.levels.WARN)
    return
end

-- Check if codewindow can be loaded
local ok, codewindow = pcall(require, 'codewindow')
if not ok then
    vim.notify("Codewindow plugin not available", vim.log.levels.WARN)
    return
end

-- Finally set up codewindow
if vim.g.code_preview_enabled then
    codewindow.setup({
        auto_enable = false,
        use_treesitter = true,
        exclude_filetypes = {
            'help', 'dashboard', 'NvimTree', 'Trouble', 
            'TelescopePrompt', 'Float', 'Startify',
        },
    })
    
    -- Add toggle keymap
    vim.keymap.set('n', '<leader>mm', function()
        codewindow.toggle_minimap()
    end, { desc = 'Toggle minimap' })
end