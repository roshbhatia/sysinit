local M = {}

M.plugins = {{
    "petertriho/nvim-scrollbar",
    lazy = false,
    dependencies = {
        "lewis6991/gitsigns.nvim",
        "kevinhwang91/nvim-hlslens",
    },
    config = function()
        require("scrollbar").setup({
            -- Scrollbar appearance
            show = true,
            handle = {
                text = " ",
                color = "ScrollbarHandle",
                hide_if_all_visible = true,
            },
            marks = {
                Search = { color = "Orange" },
                Error = { color = "Red" },
                Warn = { color = "Yellow" },
                Info = { color = "Blue" },
                Hint = { color = "Green" },
                Misc = { color = "Purple" },
            },
            excluded_filetypes = {
                "prompt",
                "TelescopePrompt",
                "noice",
                "NvimTree",
                "alpha",
            },
            autocmd = {
                render = {
                    "BufWinEnter",
                    "TabEnter",
                    "TermEnter",
                    "WinEnter",
                    "CmdwinLeave",
                    "TextChanged",
                    "VimResized",
                    "WinScrolled",
                },
            },
        })
        
        
        local ok, _ = pcall(require, "hlslens")
        if ok then
            require("scrollbar.handlers.search").setup()
        end
        
        local ok2, _ = pcall(require, "gitsigns")
        if ok2 then
            require("scrollbar.handlers.gitsigns").setup()
        end
        
        require("scrollbar.handlers.diagnostics").setup()
    end
}}

return M
