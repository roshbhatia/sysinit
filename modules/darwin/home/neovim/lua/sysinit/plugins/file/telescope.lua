local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {{
        "<leader>ff",
        "<cmd>Telescope find_files<cr>",
        desc = "Picker: find files"
    }, {
        "<leader>fg",
        "<cmd>Telescope live_grep<cr>",
        desc = "Picker: live grep"
    }, {
        "<leader>fb",
        "<cmd>Telescope buffers<cr>",
        desc = "Picker: find buffers"
    }, {
        "<leader>fh",
        "<cmd>Telescope help_tags<cr>",
        desc = "Picker: help tags"
    }, {
        "<leader><leader>",
        "<cmd>Telescope cmdline<cr>",
        desc = "Command Line"
    }},
    dependencies = {{"nvim-lua/plenary.nvim"}, {
        "nvim-tree/nvim-web-devicons",
        lazy = true
    }, {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make"
    }, 'jonarrien/telescope-cmdline.nvim'},
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({
            defaults = {
                prompt_prefix = " ",
                selection_caret = " ",
                path_display = {"smart"},
                file_ignore_patterns = {"node_modules", "%.git", "%.DS_Store", "%.class"},
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-n>"] = actions.cycle_history_next,
                        ["<C-p>"] = actions.cycle_history_prev,
                        ["<C-c>"] = actions.close,
                        ["<CR>"] = actions.select_default,
                        ["<C-x>"] = actions.select_horizontal,
                        ["<C-v>"] = actions.select_vertical,
                        ["<C-t>"] = actions.select_tab,
                        ["<C-u>"] = actions.preview_scrolling_up,
                        ["<C-d>"] = actions.preview_scrolling_down,
                        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist
                    },
                    n = {
                        ["<esc>"] = actions.close,
                        ["j"] = actions.move_selection_next,
                        ["k"] = actions.move_selection_previous,
                        ["H"] = actions.move_to_top,
                        ["M"] = actions.move_to_middle,
                        ["L"] = actions.move_to_bottom,
                        ["<Down>"] = actions.move_selection_next,
                        ["<Up>"] = actions.move_selection_previous,
                        ["gg"] = actions.move_to_top,
                        ["G"] = actions.move_to_bottom,
                        ["<C-u>"] = actions.preview_scrolling_up,
                        ["<C-d>"] = actions.preview_scrolling_down,
                        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                        ["?"] = actions.which_key
                    }
                }
            },
            pickers = {
                find_files = {
                    find_command = {"fd", "--type", "f", "--strip-cwd-prefix"}
                }
            },
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case"
                },
                cmdline = {
                    -- Adjust telescope picker size and layout
                    picker = {
                        layout_config = {
                            width = 120,
                            height = 25
                        }
                    },
                    -- Adjust your mappings 
                    mappings = {
                        complete = '<Tab>',
                        run_selection = '<C-CR>',
                        run_input = '<CR>'
                    },
                    -- Triggers any shell command using overseer.nvim (`:!`)
                    overseer = {
                        enabled = true
                    }
                }
            }
        })

        telescope.load_extension("fzf")
        telescope.load_extension("cmdline")

        vim.api.nvim_set_keymap('n', ':', ':Telescope cmdline<CR>', {
            noremap = true,
            desc = "Cmdline"
        })
    end
}}

return M
