-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-neo-tree/neo-tree.nvim/refs/heads/main/doc/neo-tree.txt"
local M = {}

M.plugins = {{
    "nvim-neo-tree/neo-tree.nvim",
    event = "VeryLazy",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim"},
    config = function()
        vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

        local right_click_menu = require "sysinit.pkg.right_click_menu"

        local buf_is_neotree = function()
            return vim.bo.filetype == "neo-tree"
        end

        local items = {
            newfile = right_click_menu.menu_item {
                id = "NeoTreePopUpNewFile",
                label = "New File",
                condition = buf_is_neotree,
                command = "a"
            },
            new_dir = right_click_menu.menu_item {
                label = "New Directory",
                condition = buf_is_neotree,
                command = "A"
            },
            rename = right_click_menu.menu_item {
                label = "Rename",
                condition = buf_is_neotree,
                command = "r"
            },
            delete = right_click_menu.menu_item {
                label = "Delete",
                condition = buf_is_neotree,
                command = "D"
            },
            copy = right_click_menu.menu_item {
                label = "Copy",
                condition = buf_is_neotree,
                command = "c"
            },
            paste = right_click_menu.menu_item {
                label = "Paste",
                condition = buf_is_neotree,
                command = "p"
            },
            open = right_click_menu.menu_item {
                label = "Open",
                condition = buf_is_neotree,
                command = "o"
            },
            close = right_click_menu.menu_item {
                label = "Close",
                condition = buf_is_neotree,
                command = "q"
            }
        }

        local neotree_menu = right_click_menu.menu_item {
            id = "NeoTreePopUp",
            label = "Files",
            condition = buf_is_neotree,
            items = {items.newfile, items.new_dir, items.rename, items.delete, items.copy, items.paste, items.open,
                     items.close}
        }

        right_click_menu.menu(neotree_menu)

        require("neo-tree").setup({
            close_if_last_window = true,
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = false,

            default_component_configs = {
                indent = {
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    indent_size = 2,
                    with_expanders = true, -- expander arrows for folders
                    expander_collapsed = "",
                    expander_expanded = ""
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "",
                    default = ""
                },
                git_status = {
                    symbols = {
                        -- Change type
                        added = "✚",
                        deleted = "✖",
                        modified = "",
                        renamed = "󰁕",
                        -- Status type
                        untracked = "",
                        ignored = "",
                        unstaged = "󰄱",
                        staged = "",
                        conflict = ""
                    }
                },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = true
                }
            },

            window = {
                position = "left",
                width = 35,
                mappings = {
                    ["<space>"] = "toggle_node",
                    ["<2-LeftMouse>"] = "open",
                    ["<cr>"] = "open",
                    ["S"] = "open_split",
                    ["s"] = "open_vsplit",
                    ["t"] = "open_tabnew",
                    ["C"] = "close_node",
                    ["z"] = "close_all_nodes",
                    ["R"] = "refresh",
                    ["a"] = {
                        "add",
                        config = {
                            show_path = "relative" -- "none", "relative", "absolute"
                        }
                    },
                    ["A"] = "add_directory",
                    ["d"] = "delete",
                    ["r"] = "rename",
                    ["y"] = "copy_to_clipboard",
                    ["x"] = "cut_to_clipboard",
                    ["p"] = "paste_from_clipboard",
                    ["c"] = "copy",
                    ["m"] = "move",
                    ["q"] = "close_window",
                    ["?"] = "show_help",
                    ["<"] = "prev_source",
                    [">"] = "next_source"
                }
            },

            nesting_rules = {
                ["js"] = {"js.map"},
                ["package.json"] = {
                    pattern = "^package%.json$",
                    files = {"package-lock.json", "yarn.lock"}
                }
            },

            filesystem = {
                filtered_items = {
                    visible = false, -- when true, they will just be displayed differently than normal items
                    hide_dotfiles = true,
                    hide_gitignored = true,
                    hide_hidden = true, -- only works on Windows for hidden files/directories
                    hide_by_name = {".DS_Store", "thumbs.db", "node_modules"},
                    hide_by_pattern = { -- uses glob style patterns
                    "*.meta"},
                    always_show = { -- remains visible even if other settings would hide it
                    ".gitignored"},
                    never_show = { -- remains hidden even if visible is toggled to true
                    ".DS_Store"}
                },
                follow_current_file = {
                    enabled = true, -- Focus the file that is currently being edited
                    leave_dirs_open = true -- Leave directories open when focusing a file
                },
                group_empty_dirs = false, -- when true, empty folders will be grouped together
                hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
                window = {
                    mappings = {
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified"
                    }
                }
            },

            buffers = {
                follow_current_file = {
                    enabled = true -- focus the file in the buffer list that is currently being edited
                },
                group_empty_dirs = true, -- when true, empty directories will be grouped together
                show_unloaded = true,
                window = {
                    mappings = {
                        ["bd"] = "buffer_delete",
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root"
                    }
                }
            },

            git_status = {
                window = {
                    mappings = {
                        ["A"] = "git_add_all",
                        ["ga"] = "git_add_file",
                        ["gu"] = "git_unstage_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gp"] = "git_push",
                        ["gg"] = "git_commit_and_push"
                    }
                }
            }
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "neo-tree",
            callback = function()
                vim.opt_local.number = false
                vim.opt_local.relativenumber = false
                vim.api.nvim_buf_set_name(0, "File Explorer")
            end
        })
    end
}}

return M
