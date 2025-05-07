local M = {}

M.plugins = {{
    "lewis6991/gitsigns.nvim",
    event = {"BufReadPre", "BufNewFile"},
    config = function()
        require("gitsigns").setup({
            signs = {
                add = {
                    text = "▎"
                },
                change = {
                    text = "▎"
                },
                delete = {
                    text = "▎"
                },
                topdelete = {
                    text = "▎"
                },
                changedelete = {
                    text = "▎"
                },
                untracked = {
                    text = "▎"
                }
            },
            signcolumn = true,
            numhl = false,
            linehl = false,
            word_diff = false,
            watch_gitdir = {
                follow_files = true
            },
            attach_to_untracked = true,
            current_line_blame = false,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 1000,
                ignore_whitespace = false
            },
            current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
            sign_priority = 6,
            update_debounce = 100,
            status_formatter = nil,
            max_file_length = 40000,
            preview_config = {
                border = "single",
                style = "minimal",
                relative = "cursor",
                row = 0,
                col = 1
            },
            yadm = {
                enable = false
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map("n", "]c", function()
                    if vim.wo.diff then
                        return "]c"
                    end
                    vim.schedule(function()
                        gs.next_hunk()
                    end)
                    return "<Ignore>"
                end, {
                    expr = true
                })

                map("n", "[c", function()
                    if vim.wo.diff then
                        return "[c"
                    end
                    vim.schedule(function()
                        gs.prev_hunk()
                    end)
                    return "<Ignore>"
                end, {
                    expr = true
                })

                -- Actions
                map("n", "<leader>ghs", gs.stage_hunk, {
                    desc = "Git: Stage hunk"
                })

                map("n", "<leader>ghr", gs.reset_hunk, {
                    desc = "Git: Reset hunk"
                })

                map("v", "<leader>ghs", function()
                    gs.stage_hunk({vim.fn.line("."), vim.fn.line("v")})
                end, {
                    desc = "Git: Stage selected hunk"
                })

                map("v", "<leader>ghr", function()
                    gs.reset_hunk({vim.fn.line("."), vim.fn.line("v")})
                end, {
                    desc = "Git: Reset selected hunk"
                })

                map("n", "<leader>ghS", gs.stage_buffer, {
                    desc = "Git: Stage buffer"
                })

                map("n", "<leader>ghu", gs.undo_stage_hunk, {
                    desc = "Git: Undo stage hunk"
                })

                map("n", "<leader>ghR", gs.reset_buffer, {
                    desc = "Git: Reset buffer"
                })

                map("n", "<leader>ghp", gs.preview_hunk, {
                    desc = "Git: Preview hunk"
                })

                map("n", "<leader>gtb", gs.toggle_current_line_blame, {
                    desc = "Git: Toggle line blame"
                })

                map("n", "<leader>ghd", gs.diffthis, {
                    desc = "Git: Diff this"
                })

                map("n", "<leader>ghD", function()
                    gs.diffthis("~")
                end, {
                    desc = "Git: Diff this ~"
                })

                map("n", "<leader>gtd", gs.toggle_deleted, {
                    desc = "Git: Toggle deleted"
                })

                -- Text object
                map({"o", "x"}, "ih", ":<C-U>Gitsigns select_hunk<CR>", {
                    desc = "Git: Select hunk"
                })
            end
        })
    end
}}

return M
