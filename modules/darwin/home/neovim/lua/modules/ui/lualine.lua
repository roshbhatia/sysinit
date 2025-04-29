-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-lualine/lualine.nvim/refs/heads/master/doc/lualine.txt"
local M = {}

M.plugins = {{
    'nvim-lualine/lualine.nvim',
    dependencies = {'nvim-tree/nvim-web-devicons', 'lewis6991/gitsigns.nvim'},
    config = function()
        -- Custom colors for neo theme with transparency
        local colors = {
            bg = 'none',
            fg = '#bbc2cf',
            yellow = '#ECBE7B',
            cyan = '#008080',
            darkblue = '#081633',
            green = '#98be65',
            orange = '#FF8800',
            violet = '#a9a1e1',
            magenta = '#c678dd',
            blue = '#51afef',
            red = '#ec5f67',
            git_add = '#98be65',
            git_mod = '#ECBE7B',
            git_del = '#ec5f67'
        }

        -- Custom mode colors
        local mode_colors = {
            n = colors.blue,
            i = colors.green,
            v = colors.magenta,
            [''] = colors.magenta,
            V = colors.magenta,
            c = colors.orange,
            no = colors.red,
            s = colors.violet,
            S = colors.violet,
            [''] = colors.violet,
            ic = colors.yellow,
            R = colors.red,
            Rv = colors.red,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ['r?'] = colors.cyan,
            ['!'] = colors.red,
            t = colors.green
        }

        -- Customized separators
        local left_sep = '' -- A slanted separator
        local right_sep = '' -- A slanted separator

        -- Custom mode display with icons
        local mode_map = {
            ['n'] = 'NORMAL',
            ['no'] = 'O-PENDING',
            ['nov'] = 'O-PENDING',
            ['noV'] = 'O-PENDING',
            ['no'] = 'O-PENDING',
            ['niI'] = 'NORMAL',
            ['niR'] = 'NORMAL',
            ['niV'] = 'NORMAL',
            ['nt'] = 'NORMAL',
            ['v'] = 'VISUAL',
            ['vs'] = 'VISUAL',
            ['V'] = 'V-LINE',
            ['Vs'] = 'V-LINE',
            [''] = 'V-BLOCK',
            ['s'] = 'V-BLOCK',
            ['s'] = 'SELECT',
            ['S'] = 'S-LINE',
            [''] = 'S-BLOCK',
            ['i'] = 'INSERT',
            ['ic'] = 'INSERT',
            ['ix'] = 'INSERT',
            ['R'] = 'REPLACE',
            ['Rc'] = 'REPLACE',
            ['Rx'] = 'REPLACE',
            ['Rv'] = 'V-REPLACE',
            ['Rvc'] = 'V-REPLACE',
            ['Rvx'] = 'V-REPLACE',
            ['c'] = 'COMMAND',
            ['cv'] = 'EX',
            ['ce'] = 'EX',
            ['r'] = 'PROMPT',
            ['rm'] = 'MORE',
            ['r?'] = 'CONFIRM',
            ['!'] = 'SHELL',
            ['t'] = 'TERMINAL'
        }

        -- Enhanced mode component
        local mode = {
            function()
                local m = vim.api.nvim_get_mode().mode
                local current_mode = mode_map[m] or m
                local mode_icon = ""

                if current_mode:match("NORMAL") then
                    mode_icon = " "
                elseif current_mode:match("INSERT") then
                    mode_icon = " "
                elseif current_mode:match("VISUAL") or current_mode:match("V%-") then
                    mode_icon = " "
                elseif current_mode:match("COMMAND") then
                    mode_icon = " "
                elseif current_mode:match("TERMINAL") then
                    mode_icon = " "
                elseif current_mode:match("REPLACE") then
                    mode_icon = " "
                end

                return mode_icon .. " " .. current_mode
            end,
            separator = {
                left = left_sep,
                right = right_sep
            },
            padding = {
                left = 1,
                right = 1
            },
            color = function()
                return {
                    bg = mode_colors[vim.api.nvim_get_mode().mode],
                    fg = '#1e222a'
                }
            end
        }

        -- Enhanced file icon and name
        local function file_info()
            local file = vim.fn.expand('%:t')
            local file_extension = vim.fn.expand('%:e')
            local icon, icon_color

            local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
            if has_devicons and file ~= '' then
                icon, icon_color = devicons.get_icon_color(file, file_extension, {
                    default = true
                })
            else
                icon, icon_color = '', '#ffffff'
            end

            local filename = file ~= '' and file or '[No Name]'
            local modified = vim.bo.modified and ' [+]' or ''

            local readonly = ''
            if vim.bo.readonly then
                readonly = ' '
            end

            return icon .. ' ' .. filename .. modified .. readonly
        end

        -- Enhanced diagnostics component
        local diagnostics = {
            "diagnostics",
            sources = {"nvim_diagnostic"},
            sections = {"error", "warn", "info", "hint"},
            symbols = {
                error = " ",
                warn = " ",
                info = " ",
                hint = " "
            },
            diagnostics_color = {
                error = {
                    fg = colors.red
                },
                warn = {
                    fg = colors.yellow
                },
                info = {
                    fg = colors.blue
                },
                hint = {
                    fg = colors.green
                }
            },
            colored = true,
            update_in_insert = false,
            always_visible = false
        }

        -- Enhanced git component
        local diff = {
            "diff",
            colored = true,
            diff_color = {
                added = {
                    fg = colors.git_add
                },
                modified = {
                    fg = colors.git_mod
                },
                removed = {
                    fg = colors.git_del
                }
            },
            symbols = {
                added = " ",
                modified = " ",
                removed = " "
            },
            source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                    return {
                        added = gitsigns.added,
                        modified = gitsigns.changed,
                        removed = gitsigns.removed
                    }
                end
            end,
            cond = function()
                return vim.g.gitsigns_head or vim.b.gitsigns_head
            end
        }

        -- Enhanced git branch component
        local branch = {
            "branch",
            icon = " ",
            color = {
                fg = colors.violet,
                gui = "bold"
            }
        }

        -- LSP clients and servers info
        local function lsp_client_names()
            local clients = {}
            for _, client in pairs(vim.lsp.get_active_clients({
                bufnr = 0
            })) do
                table.insert(clients, client.name)
            end

            if #clients == 0 then
                return ""
            else
                return " " .. table.concat(clients, ", ")
            end
        end

        -- Enhanced filetype component
        local filetype = {
            "filetype",
            colored = true,
            icon_only = false,
            padding = {
                left = 1,
                right = 1
            }
        }

        -- Better location component
        local location = {
            function()
                local line = vim.fn.line('.')
                local col = vim.fn.virtcol('.')
                local total_lines = vim.fn.line('$')
                return string.format("%d:%d/%d", line, col, total_lines)
            end,
            padding = {
                left = 1,
                right = 1
            },
            color = {
                fg = colors.fg,
                gui = "bold"
            }
        }

        -- Progress component
        local progress = {
            function()
                local current_line = vim.fn.line('.')
                local total_lines = vim.fn.line('$')
                local chars = {"__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██"}
                local line_ratio = current_line / total_lines
                local index = math.ceil(line_ratio * #chars)
                return chars[index]
            end,
            padding = {
                left = 0,
                right = 0
            },
            color = {
                fg = colors.blue,
                bg = colors.bg
            }
        }

        -- Indentation info
        local spaces = function()
            local indent_type = vim.bo.expandtab and "Spaces" or "Tabs"
            local indent_size = vim.bo.expandtab and vim.bo.shiftwidth or vim.bo.tabstop
            return indent_type .. ": " .. indent_size
        end

        -- Session component
        local session = function()
            local status_ok, auto_session_lib = pcall(require, "auto-session.lib")
            if not status_ok then
                return ""
            end

            local session_name = auto_session_lib.current_session_name(true)
            if session_name and session_name ~= "" then
                return "󱂬 " .. session_name
            else
                return ""
            end
        end

        -- Macro recording indicator
        local macro = {
            function()
                local recording_register = vim.fn.reg_recording()
                if recording_register == "" then
                    return ""
                else
                    return "Recording @" .. recording_register
                end
            end,
            color = {
                fg = colors.red
            }
        }

        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'auto',
                component_separators = {
                    left = '|',
                    right = '|'
                },
                section_separators = {
                    left = left_sep,
                    right = right_sep
                },
                disabled_filetypes = {
                    statusline = {'NvimTree', 'alpha', 'dashboard'},
                    winbar = {}
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = true,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000
                }
            },
            sections = {
                lualine_a = {mode},
                lualine_b = {branch, diff, {
                    macro,
                    color = {
                        fg = colors.red,
                        gui = "bold"
                    }
                }},
                lualine_c = {{file_info}, {
                    session,
                    color = {
                        fg = colors.green,
                        gui = "italic"
                    }
                }},
                lualine_x = {diagnostics, {
                    lsp_client_names,
                    color = {
                        fg = colors.blue,
                        gui = "bold"
                    }
                }, {
                    spaces,
                    color = {
                        fg = colors.orange,
                        gui = "bold"
                    },
                    padding = {
                        left = 1,
                        right = 1
                    }
                }, {
                    "encoding",
                    color = {
                        fg = colors.violet,
                        gui = "bold"
                    },
                    padding = {
                        left = 1,
                        right = 0
                    }
                }, filetype},
                lualine_y = {location},
                lualine_z = {{
                    "progress",
                    color = {
                        bg = colors.blue,
                        fg = colors.darkblue
                    }
                }, progress}
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {{
                    file_info,
                    color = {
                        fg = colors.fg,
                        gui = "italic"
                    }
                }},
                lualine_x = {location},
                lualine_y = {},
                lualine_z = {}
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {'fugitive', 'nvim-tree', 'toggleterm', 'lazy', 'trouble', 'neo-tree'}
        }
    end
}}

return M
