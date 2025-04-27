-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {{
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    event = "BufReadPost",
    config = function()
        local neominimap = require("neominimap")

        local config = {
            auto_enable = false,

            log_level = vim.log.levels.OFF,
            notification_level = vim.log.levels.INFO,
            exclude_filetypes = {"help", "bigfile", "neo-tree", "lazy", "mason", "oil", "alpha", "dashboard",
                                 "TelescopePrompt", "toggleterm"},
            exclude_buftypes = {"nofile", "nowrite", "quickfix", "terminal", "prompt"},
            x_multiplier = 4,
            y_multiplier = 1,
            layout = "float",
            split = {
                minimap_width = 20,
                fix_width = true,
                direction = "right",
                close_if_last_window = true
            },
            float = {
                minimap_width = 20,
                max_minimap_height = nil,
                margin = {
                    right = 0,
                    top = 0,
                    bottom = 0
                },
                z_index = 10,
                window_border = "single"
            },
            delay = 200,
            sync_cursor = true,
            click = {
                enabled = true,
                auto_switch_focus = false
            },
            diagnostic = {
                enabled = true,
                severity = vim.diagnostic.severity.WARN,
                mode = "line"
            },
            git = {
                enabled = true,
                mode = "sign"
            },
            treesitter = {
                enabled = true
            },
            search = {
                enabled = true,
                mode = "line"
            },
            mark = {
                enabled = true,
                mode = "icon",
                show_builtins = false
            },
            fold = {
                enabled = true
            },
            winopt = function(opt, winid)
                opt.winblend = 10 -- Semi-transparent minimap
            end,
            bufopt = function(opt, bufnr)
                -- Add any custom buffer options here
            end
        }

        vim.g.neominimap = config

        -- Initialize lualine integration if lualine is available
        local has_lualine, _ = pcall(require, "lualine")
        if has_lualine then
            local minimap_extension = require("neominimap.statusline").lualine_default
            require('lualine').setup({
                extensions = vim.list_extend(require('lualine').extensions or {}, {minimap_extension})
            })
        end

        -- Set up highlight groups for better integration with your colorscheme
        vim.api.nvim_create_autocmd("ColorScheme", {
            pattern = "*",
            callback = function()
                -- Basic minimap highlights
                vim.api.nvim_set_hl(0, "NeominimapBackground", {
                    link = "Normal"
                })
                vim.api.nvim_set_hl(0, "NeominimapBorder", {
                    link = "FloatBorder"
                })
                vim.api.nvim_set_hl(0, "NeominimapCursorLine", {
                    link = "CursorLine"
                })

                -- Diagnostic highlights
                vim.api.nvim_set_hl(0, "NeominimapErrorLine", {
                    link = "DiagnosticVirtualTextError"
                })
                vim.api.nvim_set_hl(0, "NeominimapWarnLine", {
                    link = "DiagnosticVirtualTextWarn"
                })
                vim.api.nvim_set_hl(0, "NeominimapInfoLine", {
                    link = "DiagnosticVirtualTextInfo"
                })
                vim.api.nvim_set_hl(0, "NeominimapHintLine", {
                    link = "DiagnosticVirtualTextHint"
                })

                -- Git highlights
                vim.api.nvim_set_hl(0, "NeominimapGitAddLine", {
                    link = "DiffAdd"
                })
                vim.api.nvim_set_hl(0, "NeominimapGitChangeLine", {
                    link = "DiffChange"
                })
                vim.api.nvim_set_hl(0, "NeominimapGitDeleteLine", {
                    link = "DiffDelete"
                })

                -- Search highlights
                vim.api.nvim_set_hl(0, "NeominimapSearchLine", {
                    link = "Search"
                })
            end
        })

        -- Function to check if current window is the rightmost one
        local function is_rightmost_window()
            local mux = require('smart-splits.mux').get()
            if mux and mux.current_pane_at_edge then
                return mux.current_pane_at_edge('right')
            else
                -- Fallback when multiplexer is not available
                local win_id = vim.api.nvim_get_current_win()
                local wins = vim.api.nvim_tabpage_list_wins(0)

                -- Get window positions
                local positions = {}
                for _, id in ipairs(wins) do
                    local pos = vim.api.nvim_win_get_position(id)
                    local width = vim.api.nvim_win_get_width(id)
                    positions[id] = {
                        col = pos[2],
                        right_edge = pos[2] + width
                    }
                end

                -- Check if current window has the rightmost edge
                local current_right = positions[win_id].right_edge
                for id, pos in pairs(positions) do
                    if id ~= win_id and pos.right_edge > current_right then
                        return false
                    end
                end
                return true
            end
        end
    end
}}

return M
