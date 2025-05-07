-- AI assistance and UI integration module for Neovim
local M = {}

M.plugins = {
    -- GitHub Copilot for code completions
    {
        "github/copilot.vim", -- Official GitHub Copilot plugin
        lazy = false,
        config = function()
            -- Configure Copilot
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_assume_mapped = true
            vim.g.copilot_tab_fallback = ""

            -- Use <C-j> for accepting Copilot suggestions
            vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("\<CR>")', { expr = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-]>", "<Plug>(copilot-next)", { silent = true })
            vim.api.nvim_set_keymap("i", "<C-[>", "<Plug>(copilot-previous)", { silent = true })
            vim.api.nvim_set_keymap("i", "<C-\\>", "<Plug>(copilot-dismiss)", { silent = true })
        end
    },

    -- Aider.nvim for AI-assisted coding
    {
        "GeorgesAlkhouri/nvim-aider", -- Aider nvim integration
        cmd = "Aider",
        dependencies = {
            "folke/snacks.nvim",
            -- Optional dependencies
            "catppuccin/nvim",
            "nvim-tree/nvim-tree.lua",
            -- Neo-tree integration
            {
                "nvim-neo-tree/neo-tree.nvim",
                opts = function(_, opts)
                    require("nvim_aider.neo_tree").setup(opts)
                end,
            },
        },
        config = function()
            require("nvim_aider").setup({
                -- Command that executes Aider
                aider_cmd = "aider",
                -- Command line arguments passed to aider
                args = {
                    "--no-auto-commits",
                    "--pretty",
                    "--stream",
                },
                -- Automatically reload buffers changed by Aider
                auto_reload = true,
                win = {
                    wo = { winbar = "Aider" },
                    style = "nvim_aider",
                    position = "right",
                },
            })
        end
    },

    -- NvChad UI components
    { "nvim-lua/plenary.nvim" },
    { "nvim-tree/nvim-web-devicons", lazy = true },

    {
        "nvchad/ui",
        dependencies = {
            "nvchad/base46",
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

    -- Theme switcher (optional)
    "nvchad/volt",
}

function M.setup()
    -- Set up Base46 cache
    vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

    -- Load specific UI components
    vim.schedule(function()
        -- Load only specific components we need
        dofile(vim.g.base46_cache .. "defaults")
        dofile(vim.g.base46_cache .. "statusline")
        dofile(vim.g.base46_cache .. "lsp")
        dofile(vim.g.base46_cache .. "cmp")
    end)

    -- Configure NvChad UI components
    local present, ui = pcall(require, "nvchad.ui")
    if present then
        -- Enable the UI components we want
        ui.statusline.setup()
        ui.lsp.setup()
        ui.cmp_themes.setup()
        ui.tabufline.setup()
    end

    -- Setup LSP signature (part of NvChad UI)
    local present_lsp, lsp = pcall(require, "nvchad.ui.lsp")
    if present_lsp then
        lsp.signature.setup()
    end

    -- Setup variable renaming for LSP
    local present_renamer, renamer = pcall(require, "nvchad.ui.lsp.renamer")
    if present_renamer then
        renamer.setup()
    end
end

return M