-- AI tools integration for Neovim
-- Combines GitHub Copilot, Aider, and NvChad UI components
local M = {}

function M.init()
    -- Load individual components
    local nvchad_ui = require("sysinit.plugins.intellicode.nvchad-ui")
    local copilot = require("sysinit.plugins.intellicode.copilot")
    local aider = require("sysinit.plugins.intellicode.aider")
    
    -- Return a merged list of plugin specifications
    return {
        -- Copilot specifications
        copilot.get_plugin_spec(),
        
        -- Aider specifications
        aider.get_plugin_spec(),
        
        -- NvChad UI specifications (returns multiple specs)
        unpack(nvchad_ui.get_plugin_spec()),
        
        -- Required dependencies
        "nvim-lua/plenary.nvim",
        { "nvim-tree/nvim-web-devicons", lazy = true },
    }
end

function M.setup()
    -- Set up Base46 cache path for NvChad UI (must be before lazy.nvim setup)
    vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
    
    -- Initialize individual components
    local nvchad_ui = require("sysinit.plugins.intellicode.nvchad-ui")
    local copilot = require("sysinit.plugins.intellicode.copilot")
    local aider = require("sysinit.plugins.intellicode.aider")
    
    -- Configure components
    nvchad_ui.setup({
        -- Statusline config
        statusline = {
            theme = "default",  -- Options: default, vscode, minimal, arrow
            separator_style = "block",
        },
        
        -- CMP/completion styling
        cmp = {
            style = "atom_colored",
            selected_item_bg = "colored",
        },
    })
    
    -- Set up Copilot
    copilot.setup({
        enabled = true,
        auto_start = true,
        keymaps = {
            accept = "<C-j>",
            next = "<C-]>",
            prev = "<C-[>",
            dismiss = "<C-\\>",
        }
    })
    
    -- Set up Aider
    aider.setup({
        auto_reload = true,
        window = {
            position = "right",
        }
    })
    
    -- Set global options needed by AI tools
    vim.opt.autoread = true
    vim.opt.updatetime = 100
    vim.opt.termguicolors = true
    
    -- Add helpful commands
    vim.api.nvim_create_user_command("AI", "Aider toggle", {})
    vim.api.nvim_create_user_command("Copilot", "Copilot", { nargs = "*" })
end

-- For those who want to load specific components only
M.components = {
    nvchad_ui = require("sysinit.plugins.intellicode.nvchad-ui"),
    copilot = require("sysinit.plugins.intellicode.copilot"),
    aider = require("sysinit.plugins.intellicode.aider"),
}

return M
