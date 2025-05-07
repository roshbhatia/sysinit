-- AI assistance and UI keymaps module for Neovim
local M = {}

function M.setup()
    ----------------------------------------
    -- GitHub Copilot keybindings
    ----------------------------------------
    -- Note: Most Copilot insert mode keymaps are set in the module config
    vim.keymap.set('n', '<leader>cpe', '<cmd>Copilot enable<CR>', { desc = 'Enable Copilot' })
    vim.keymap.set('n', '<leader>cpd', '<cmd>Copilot disable<CR>', { desc = 'Disable Copilot' })
    vim.keymap.set('n', '<leader>cps', '<cmd>Copilot status<CR>', { desc = 'Copilot Status' })

    ----------------------------------------
    -- Aider.nvim keybindings
    ----------------------------------------
    -- Main commands
    vim.keymap.set('n', '<leader>at', '<cmd>Aider toggle<CR>', { desc = 'Toggle Aider terminal' })
    vim.keymap.set('n', '<leader>as', '<cmd>Aider send<CR>', { desc = 'Send to Aider' })
    vim.keymap.set('v', '<leader>as', ':<C-u>Aider send<CR>', { desc = 'Send selection to Aider' })
    vim.keymap.set('n', '<leader>ac', '<cmd>Aider command<CR>', { desc = 'Aider Commands' })

    -- File management
    vim.keymap.set('n', '<leader>ab', '<cmd>Aider buffer<CR>', { desc = 'Send current buffer to Aider' })
    vim.keymap.set('n', '<leader>ad', '<cmd>Aider buffer diagnostics<CR>', { desc = 'Send diagnostics to Aider' })
    vim.keymap.set('n', '<leader>a+', '<cmd>Aider add<CR>', { desc = 'Add file to Aider session' })
    vim.keymap.set('n', '<leader>a-', '<cmd>Aider drop<CR>', { desc = 'Remove file from Aider session' })
    vim.keymap.set('n', '<leader>ar', '<cmd>Aider add readonly<CR>', { desc = 'Add file as read-only to Aider' })
    vim.keymap.set('n', '<leader>aR', '<cmd>Aider reset<CR>', { desc = 'Reset Aider session' })

    -- NvimTree integration (if available)
    if pcall(require, "nvim-tree") then
        vim.keymap.set('n', '<leader>a+', '<cmd>AiderTreeAddFile<CR>', { desc = 'Add file from Tree to Aider', ft = "NvimTree" })
        vim.keymap.set('n', '<leader>a-', '<cmd>AiderTreeDropFile<CR>', { desc = 'Drop file from Tree from Aider', ft = "NvimTree" })
    end

    -- Add health check binding
    vim.keymap.set('n', '<leader>ah', '<cmd>Aider health<CR>', { desc = 'Check Aider health status' })

    ----------------------------------------
    -- NvChad UI keybindings
    ----------------------------------------

    -- Theme switching
    vim.keymap.set('n', '<leader>th', '<cmd>Telescope themes<CR>', { desc = 'NvChad: Switch theme' })

    -- LSP Related
    vim.keymap.set('n', '<leader>ra', function()
        local present, renamer = pcall(require, "nvchad.ui.lsp.renamer")
        if present then
            renamer.open()
        end
    end, { desc = 'LSP: Rename variable under cursor' })

    -- Statusline toggle modes
    vim.keymap.set('n', '<leader>sl', function()
        local present, statusline = pcall(require, "nvchad.ui.statusline")
        if present then
            local current_mode = statusline.config.current_mode or 1
            local next_mode = (current_mode % 4) + 1
            statusline.config.current_mode = next_mode
            vim.cmd("redrawstatus")
            vim.notify("Statusline mode: " .. next_mode, vim.log.levels.INFO)
        end
    end, { desc = 'Cycle statusline modes' })

    -- Tab management
    vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<CR>', { desc = 'Create new tab' })
    vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<CR>', { desc = 'Close current tab' })
    vim.keymap.set('n', '<leader>tp', '<cmd>tabprevious<CR>', { desc = 'Go to previous tab' })
    vim.keymap.set('n', '<leader>tN', '<cmd>tabnext<CR>', { desc = 'Go to next tab' })

    -- Buffer management (via NvChad tabufline)
    vim.keymap.set('n', '<leader>cb', function()
        local present, nvchad = pcall(require, "nvchad.tabufline")
        if present then
            nvchad.close_buffer()
        else
            vim.cmd("bdelete")
        end
    end, { desc = 'Close current buffer' })

    -- Toggle cheatsheet
    vim.keymap.set('n', '<leader>ch', '<cmd>NvCheatsheet<CR>', { desc = 'Open keybindings cheatsheet' })

    -- Create a keymap for LSP signature help
    vim.keymap.set('n', '<leader>sh', function()
        local present, signature = pcall(require, "nvchad.ui.lsp.signature")
        if present then
            signature.toggle()
        end
    end, { desc = 'Toggle LSP signature help' })

    -- CMP completion toggle
    vim.keymap.set('n', '<leader>ct', function()
        -- Toggle completion on/off
        if vim.g.cmp_enabled == false then
            vim.g.cmp_enabled = true
            vim.notify("Code completion enabled", vim.log.levels.INFO)
        else
            vim.g.cmp_enabled = false
            vim.notify("Code completion disabled", vim.log.levels.INFO)
        end
    end, { desc = 'Toggle code completion' })
end

return M