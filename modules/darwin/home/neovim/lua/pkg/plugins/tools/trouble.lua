local M = {}

M.plugins = {{
    "folke/trouble.nvim",
    lazy = true,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    opts = {
        position = "bottom",
        height = 10,
        width = 50,
        icons = true,
        mode = "workspace_diagnostics",
        auto_preview = true,
        auto_close = false,
        auto_open = false,
        auto_jump = false,
        use_diagnostic_signs = true,
        action_keys = {
            close = "q",
            cancel = "<esc>",
            refresh = "r",
            jump = {"<cr>", "<tab>"},
            open_split = {"<c-x>"},
            open_vsplit = {"<c-v>"},
            open_tab = {"<c-t>"},
            jump_close = {"o"},
            toggle_mode = "m",
            toggle_preview = "P",
            hover = "K",
            preview = "p",
            close_folds = {"zM", "zm"},
            open_folds = {"zR", "zr"},
            toggle_fold = {"zA", "za"},
            previous = "k",
            next = "j"
        },
        indent_lines = true,
        win_config = {
            border = "rounded"
        },
        auto_fold = false,
        signs = {
            error = "✗",
            warning = "⚠",
            hint = "➤",
            information = "ℹ",
            other = "➤"
        }
    }
}}

return M
