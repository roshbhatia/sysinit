-- Aider.nvim integration for AI-assisted coding
local M = {}

M.config = {
    cmd = "aider",
    args = {
        "--no-auto-commits",
        "--pretty",
        "--stream",
    },
    auto_reload = true,
    window = {
        position = "right",
        style = "nvim_aider",
        winbar = "Aider",
    },
}

M.keys = {
    { "<leader>at", "<cmd>Aider toggle<CR>", desc = "Toggle Aider terminal" },
    { "<leader>as", "<cmd>Aider send<CR>", desc = "Send to Aider", mode = { "n", "v" } },
    { "<leader>ac", "<cmd>Aider command<CR>", desc = "Aider Commands" },
    { "<leader>ab", "<cmd>Aider buffer<CR>", desc = "Send Buffer" },
    { "<leader>ad", "<cmd>Aider buffer diagnostics<CR>", desc = "Send diagnostics" },
    { "<leader>a+", "<cmd>Aider add<CR>", desc = "Add File" },
    { "<leader>a-", "<cmd>Aider drop<CR>", desc = "Drop File" },
    { "<leader>ar", "<cmd>Aider add readonly<CR>", desc = "Add Read-Only" },
    { "<leader>aR", "<cmd>Aider reset<CR>", desc = "Reset Session" },
}

function M.setup(opts)
    -- Merge user options with defaults
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    -- Create an abbreviated command for quick access
    vim.api.nvim_create_user_command("AI", "Aider toggle", {})
    
    -- Set up auto-reload capability
    if M.config.auto_reload then
        vim.opt.autoread = true
        
        -- Add auto-command to check for external file changes more frequently
        vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
            pattern = "*",
            callback = function()
                if vim.fn.mode() ~= "c" then
                    vim.cmd("checktime")
                end
            end,
        })
    end
    
    -- Initialize tree integration if available
    M.setup_tree_integration()
end

function M.setup_tree_integration()
    -- Check for nvim-tree integration
    local has_nvim_tree = pcall(require, "nvim-tree")
    if has_nvim_tree then
        -- Add tree-specific keymaps for Aider
        vim.keymap.set('n', '<leader>a+', '<cmd>AiderTreeAddFile<CR>', { 
            desc = 'Add file from Tree to Aider', 
            ft = "NvimTree" 
        })
        
        vim.keymap.set('n', '<leader>a-', '<cmd>AiderTreeDropFile<CR>', { 
            desc = 'Drop file from Tree from Aider', 
            ft = "NvimTree" 
        })
    end
    
    -- Check for neo-tree integration
    local has_neo_tree = pcall(require, "neo-tree")
    if has_neo_tree then
        -- Set up neo-tree integration for Aider
        local neo_tree_ok, neo_tree_aider = pcall(require, "nvim_aider.neo_tree")
        if neo_tree_ok then
            -- Configure neo-tree with Aider actions
            -- The actual setup will be handled by the plugin configuration
            vim.g.neo_tree_aider_enabled = true
        end
    end
end

-- Return specs for the plugin manager
function M.get_plugin_spec()
    return {
        "GeorgesAlkhouri/nvim-aider",
        cmd = "Aider",
        keys = M.keys,
        dependencies = {
            "folke/snacks.nvim",
            "catppuccin/nvim",
            { "nvim-neo-tree/neo-tree.nvim", optional = true },
            { "nvim-tree/nvim-tree.lua", optional = true },
        },
        config = function()
            require("nvim_aider").setup(M.config)
        end,
    }
end

return M
