-- NvChad UI integration for improved visual experience
local M = {}

M.config = {
    -- Statusline configuration
    statusline = {
        theme = "default",           -- Options: default, vscode, minimal, arrow
        separator_style = "block",   -- Options: default, round, block, arrow
        overriden_modules = nil,     -- Custom modules to override default ones
    },
    
    -- CMP (completion) styling
    cmp = {
        style = "default",           -- Options: default, flat, atom, atom_colored
        border_color = "grey",       -- Border color for completion windows
        selected_item_bg = "colored", -- Highlight style for selected items
    },
    
    -- Tabufline (tabs/buffers) configuration
    tabufline = {
        enabled = true,              -- Whether to use NvChad's tabufline
        lazyload = true,             -- Lazy-load the tabufline
        overriden_modules = nil,     -- Custom modules to override defaults
    },
    
    -- LSP UI features
    lsp = {
        -- Signature help (parameter hints)
        signature = {
            enabled = true,          -- Enable signature help
            silent = false,          -- Silent mode (no notifications)
        },
        
        -- Variable renaming UI
        renamer = {
            enabled = true,          -- Enable renamer UI
            border = "rounded",      -- Border style
            min_width = 30,          -- Minimum width of rename window
            max_width = 60,          -- Maximum width of rename window
        },
    },
}

M.keys = {
    -- Theme switching
    { "<leader>th", "<cmd>Telescope themes<CR>", desc = "Switch theme" },
    
    -- LSP UI
    { "<leader>ra", function() require("nvchad.ui.lsp.renamer").open() end, desc = "Rename variable (LSP)" },
    { "<leader>sh", function() require("nvchad.ui.lsp.signature").toggle() end, desc = "Toggle signature help" },
    
    -- Statusline
    { "<leader>sl", function()
        local statusline = require("nvchad.ui.statusline")
        local current_mode = statusline.config.current_mode or 1
        local next_mode = (current_mode % 4) + 1
        statusline.config.current_mode = next_mode
        vim.cmd("redrawstatus")
        vim.notify("Statusline mode: " .. next_mode, vim.log.levels.INFO)
    end, desc = "Cycle statusline modes" },
    
    -- Cheatsheet
    { "<leader>ch", "<cmd>NvCheatsheet<CR>", desc = "Open keybindings cheatsheet" },
}

function M.setup(opts)
    -- Merge user options with defaults
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    -- Make sure termguicolors is enabled for proper UI display
    vim.opt.termguicolors = true
    
    -- Set up Base46 cache for NvChad
    vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
    
    -- Load essential theme components in scheduled task to avoid startup delays
    vim.schedule(function()
        -- Load core components
        local cache_path = vim.g.base46_cache
        dofile(cache_path .. "defaults")
        dofile(cache_path .. "statusline")
        dofile(cache_path .. "lsp")
        dofile(cache_path .. "cmp")
    end)
    
    -- Create a command for easy theme switching
    vim.api.nvim_create_user_command("Theme", function()
        local present, themes = pcall(require, "telescope.builtin")
        if present then
            themes.colorscheme()
        else
            vim.notify("Telescope not available for theme switching", vim.log.levels.WARN)
        end
    end, {})
end

-- Return specs for the plugin manager
function M.get_plugin_spec()
    return {
        {
            "nvchad/ui",
            dependencies = {
                "nvchad/base46",
                "nvchad/volt", -- theme switcher
            },
            config = function()
                require("nvchad")
            end
        },
        {
            "nvchad/base46",
            lazy = true,
            build = function()
                require("base46").load_all_highlights()
            end,
        },
        {
            "nvchad/volt",
            cmd = {"Theme", "Telescope themes"},
            dependencies = {"nvim-telescope/telescope.nvim"},
        }
    }
end

return M
