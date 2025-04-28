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
                opt.winblend = 20 -- Semi-transparent minimap
            end
        }

        vim.g.neominimap = config

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

                vim.api.nvim_set_hl(0, "NeominimapGitAddLine", {
                    link = "DiffAdd"
                })
                vim.api.nvim_set_hl(0, "NeominimapGitChangeLine", {
                    link = "DiffChange"
                })
                vim.api.nvim_set_hl(0, "NeominimapGitDeleteLine", {
                    link = "DiffDelete"
                })

                vim.api.nvim_set_hl(0, "NeominimapSearchLine", {
                    link = "Search"
                })
            end
        })
    end
}}

return M
