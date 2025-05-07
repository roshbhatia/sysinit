-- GitHub Copilot integration
local M = {}

M.config = {
    -- Core settings
    enabled = true,
    auto_start = true,
    
    -- Keymapping configuration
    keymaps = {
        accept = "<C-j>",       -- Accept the current suggestion
        next = "<C-]>",         -- Show next suggestion
        prev = "<C-[>",         -- Show previous suggestion
        dismiss = "<C-\\>",     -- Dismiss the current suggestion
    },
    
    -- Filetypes to disable copilot
    disabled_filetypes = {
        "markdown",
        "yaml",
        "help",
        "gitcommit",
        "gitrebase",
        "hgcommit",
        "svn",
        "cvs",
    },
}

M.keys = {
    { "<leader>cpe", "<cmd>Copilot enable<CR>", desc = "Enable Copilot" },
    { "<leader>cpd", "<cmd>Copilot disable<CR>", desc = "Disable Copilot" },
    { "<leader>cps", "<cmd>Copilot status<CR>", desc = "Copilot Status" },
}

function M.setup(opts)
    -- Merge user options with defaults
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    -- Configure Copilot
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""
    
    -- Disable Copilot for specified filetypes
    for _, ft in ipairs(M.config.disabled_filetypes) do
        vim.api.nvim_create_autocmd("FileType", {
            pattern = ft,
            callback = function()
                vim.b.copilot_enabled = false
            end,
        })
    end
    
    -- Set up keymaps
    vim.api.nvim_set_keymap("i", M.config.keymaps.accept, 
        'copilot#Accept("\\<CR>")', 
        { expr = true, silent = true }
    )
    
    vim.api.nvim_set_keymap("i", M.config.keymaps.next, 
        "<Plug>(copilot-next)", 
        { silent = true }
    )
    
    vim.api.nvim_set_keymap("i", M.config.keymaps.prev, 
        "<Plug>(copilot-previous)", 
        { silent = true }
    )
    
    vim.api.nvim_set_keymap("i", M.config.keymaps.dismiss, 
        "<Plug>(copilot-dismiss)", 
        { silent = true }
    )
    
    -- Start Copilot on startup if configured
    if M.config.auto_start and M.config.enabled then
        vim.cmd("Copilot enable")
    elseif not M.config.enabled then
        vim.cmd("Copilot disable")
    end
end

-- Return specs for the plugin manager
function M.get_plugin_spec()
    return {
        "github/copilot.vim",
        cmd = {
            "Copilot",
            "Copilot!",
            "Copilot enable",
            "Copilot disable",
            "Copilot status",
        },
        event = "InsertEnter",
        keys = M.keys,
        config = function()
            M.setup({})
        end
    }
end

return M
