local M = {}

M.plugins = {{
    "sindrets/diffview.nvim",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        local actions = require("diffview.config").actions
        
        require("diffview").setup({
            enhanced_diff_hl = true,
            
            view = {
                default = {
                    layout = "diff2_horizontal",
                    winbar_info = true,
                },
                merge_tool = {
                    layout = "diff3_horizontal",
                    disable_diagnostics = true,
                    winbar_info = true,
                },
                file_history = {
                    layout = "diff2_horizontal",
                    winbar_info = true,
                },
            },
            
            file_panel = {
                win_config = {
                    position = "left",
                    width = 35,
                    type = "split",
                },
                listing_style = "tree",
                tree_options = {
                    flatten_dirs = true,
                    folder_statuses = "always",
                },
            },
            
            file_history_panel = {
                win_config = {
                    position = "bottom",
                    height = 16,
                    type = "split",
                },
            },
            
            log_options = {
                single_file = {
                    follow = true,
                    all = false,
                    merges = false,
                    reflog = false,
                },
                multi_file = {
                    follow = false,
                    all = false,
                    merges = false,
                    reflog = false,
                },
            },
            
            hooks = {
                diff_buf_read = function()
                    vim.opt_local.wrap = false
                    vim.opt_local.list = false
                    vim.opt_local.cursorline = true
                    vim.opt_local.foldmethod = "expr"
                    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                end,
            },
            
            keymaps = {
                disable_defaults = false,
                
                view = {
                    ["q"] = actions.close,
                    ["gf"] = actions.goto_file,
                    ["<C-w><C-f>"] = actions.goto_file_split,
                    ["<C-w>gf"] = actions.goto_file_tab,
                    ["<leader>b"] = actions.toggle_files,
                    ["<leader>e"] = actions.focus_files,
                    ["]x"] = actions.next_conflict,
                    ["[x"] = actions.prev_conflict,
                    ["<leader>co"] = { actions.conflict_choose, { "ours" } },
                    ["<leader>ct"] = { actions.conflict_choose, { "theirs" } },
                    ["<leader>cb"] = { actions.conflict_choose, { "base" } },
                    ["<leader>ca"] = { actions.conflict_choose, { "all" } },
                    ["dx"] = { actions.conflict_choose, { "none" } },
                },
                
                file_panel = {
                    ["j"] = actions.next_entry,
                    ["k"] = actions.prev_entry,
                    ["o"] = actions.select_entry,
                    ["<cr>"] = actions.select_entry,
                    ["<2-LeftMouse>"] = actions.select_entry,
                    ["<tab>"] = actions.select_next_entry,
                    ["<s-tab>"] = actions.select_prev_entry,
                    ["-"] = actions.toggle_stage_entry,
                    ["S"] = actions.stage_all,
                    ["U"] = actions.unstage_all,
                    ["X"] = actions.restore_entry,
                    ["R"] = actions.refresh_files,
                    ["i"] = actions.listing_style,
                },
                
                file_history_panel = {
                    ["g!"] = actions.options,
                    ["<C-d>"] = actions.open_in_diffview,
                },
            },
        })
    end
}}

return M
