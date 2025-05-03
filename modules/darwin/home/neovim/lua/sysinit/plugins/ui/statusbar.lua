-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-lualine/lualine.nvim/refs/heads/master/doc/lualine.txt"
local M = {}

-- Early return if not in VSCode - don't define anything else
if not vim.g.vscode then
    -- Only export the plugin when NOT in VSCode (when in regular Neovim)
    M.plugins = {{
        'nvim-lualine/lualine.nvim',
        dependencies = {'nvim-tree/nvim-web-devicons', 'lewis6991/gitsigns.nvim'},
        config = function()
            local colors = {
                -- These will be populated from your colorscheme
                bg = vim.fn.synIDattr(vim.fn.hlID('StatusLine'), 'bg'),
                fg = vim.fn.synIDattr(vim.fn.hlID('StatusLine'), 'fg'),
                normal_bg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg'),
                normal_fg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'fg'),
                insert_bg = vim.fn.synIDattr(vim.fn.hlID('String'), 'fg'),
                insert_fg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg'),
                visual_bg = vim.fn.synIDattr(vim.fn.hlID('Statement'), 'fg'),
                visual_fg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg'),
                replace_bg = vim.fn.synIDattr(vim.fn.hlID('Identifier'), 'fg'),
                replace_fg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg'),
                command_bg = vim.fn.synIDattr(vim.fn.hlID('Constant'), 'fg'),
                command_fg = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg'),
                error_fg = vim.fn.synIDattr(vim.fn.hlID('ErrorMsg'), 'fg'),
                error_bg = vim.fn.synIDattr(vim.fn.hlID('ErrorMsg'), 'bg'),
                warning_fg = vim.fn.synIDattr(vim.fn.hlID('WarningMsg'), 'fg'),
                warning_bg = vim.fn.synIDattr(vim.fn.hlID('WarningMsg'), 'bg')
            }

            -- Ensure we have fallback values if any color is missing
            for k, v in pairs(colors) do
                if v == "" or v == nil then
                    if k:match("_fg$") then
                        colors[k] = "#f3f3f3" -- Default light foreground
                    elseif k:match("_bg$") then
                        colors[k] = "#383a42" -- Default dark background
                    end
                end
            end

            local theme = {
                normal = {
                    a = {
                        fg = colors.normal_fg,
                        bg = colors.normal_bg,
                        gui = 'bold'
                    },
                    b = {
                        fg = colors.fg,
                        bg = colors.bg
                    },
                    c = {
                        fg = colors.fg,
                        bg = colors.bg
                    },
                    z = {
                        fg = colors.normal_fg,
                        bg = colors.normal_bg,
                        gui = 'bold'
                    }
                },
                insert = {
                    a = {
                        fg = colors.insert_fg,
                        bg = colors.insert_bg,
                        gui = 'bold'
                    }
                },
                visual = {
                    a = {
                        fg = colors.visual_fg,
                        bg = colors.visual_bg,
                        gui = 'bold'
                    }
                },
                replace = {
                    a = {
                        fg = colors.replace_fg,
                        bg = colors.replace_bg,
                        gui = 'bold'
                    }
                },
                command = {
                    a = {
                        fg = colors.command_fg,
                        bg = colors.command_bg,
                        gui = 'bold'
                    }
                },
                inactive = {
                    a = {
                        fg = colors.fg,
                        bg = colors.bg
                    },
                    b = {
                        fg = colors.fg,
                        bg = colors.bg
                    },
                    c = {
                        fg = colors.fg,
                        bg = colors.bg
                    }
                }
            }

            -- Create empty component for gaps
            local empty = require('lualine.component'):extend()
            function empty:draw(default_highlight)
                self.status = ''
                self.applied_separator = ''
                self:apply_highlights(default_highlight)
                self:apply_section_separators()
                return self.status
            end

            -- Process sections to add slants and gaps
            local function process_sections(sections)
                for name, section in pairs(sections) do
                    local left = name:sub(9, 10) < 'x'
                    for pos = 1, name ~= 'lualine_z' and #section or #section - 1 do
                        table.insert(section, pos * 2, {
                            empty,
                            color = {
                                fg = colors.bg,
                                bg = colors.bg
                            }
                        })
                    end
                    for id, comp in ipairs(section) do
                        if type(comp) ~= 'table' then
                            comp = {comp}
                            section[id] = comp
                        end
                        comp.separator = left and {
                            right = ''
                        } or {
                            left = ''
                        }
                    end
                end
                return sections
            end

            -- Modified indicator function
            local function modified()
                if vim.bo.modified then
                    return '+'
                elseif vim.bo.modifiable == false or vim.bo.readonly == true then
                    return '-'
                end
                return ''
            end

            -- Setup lualine
            require('lualine').setup {
                options = {
                    theme = theme,
                    component_separators = '',
                    section_separators = {
                        left = '',
                        right = ''
                    },
                    globalstatus = true,
                    always_divide_middle = false, -- As requested
                    disabled_filetypes = {
                        statusline = {},
                        winbar = {}
                    },
                    refresh = {
                        statusline = 100,
                        tabline = 100,
                        winbar = 100
                    }
                },
                sections = process_sections {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', {
                        'diff',
                        colored = true,
                        diff_color = {
                            added = {
                                fg = colors.insert_bg
                            },
                            modified = {
                                fg = colors.visual_bg
                            },
                            removed = {
                                fg = colors.error_fg
                            }
                        },
                        symbols = {
                            added = '+',
                            modified = '~',
                            removed = '-'
                        }
                    }, {
                        'diagnostics',
                        sources = {'nvim_diagnostic'},
                        sections = {'error', 'warn'},
                        diagnostics_color = {
                            error = {
                                fg = colors.error_fg
                            },
                            warn = {
                                fg = colors.warning_fg
                            }
                        },
                        symbols = {
                            error = ' ',
                            warn = ' '
                        }
                    }},
                    lualine_c = {{
                        'filename',
                        path = 1,
                        file_status = true,
                        shorting_target = 40
                    }, {
                        modified,
                        color = {
                            fg = colors.error_fg
                        }
                    }},
                    lualine_x = {},
                    lualine_y = {'progress'},
                    lualine_z = {'location'}
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {{
                        'filename',
                        path = 1
                    }},
                    lualine_x = {'location'},
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                extensions = {}
            }
        end
    }}

    -- Empty setup function for Neovim mode since lualine handles itself in its config
    function M.setup()
        -- Nothing needed here for regular Neovim
    end

    return M
end

-- If we reach here, we're in VSCode mode
local vscode = require('vscode')

-- VSCode mode-specific functionality
local MODE_DISPLAY = {
    n = {
        text = '󱄅 NORMAL',
        color = '#7aa2f7'
    },
    i = {
        text = ' INSERT',
        color = '#9ece6a'
    },
    v = {
        text = '󰈈 VISUAL',
        color = '#bb9af7'
    },
    V = {
        text = '󱣾 V-LINE',
        color = '#bb9af7'
    },
    ['\22'] = {
        text = '󰮔 V-BLOCK',
        color = '#bb9af7'
    },
    R = {
        text = '󰛔 REPLACE',
        color = '#f7768e'
    },
    s = {
        text = '󰴱 SELECT',
        color = '#ff9e64'
    },
    S = {
        text = '󰫙 S-LINE',
        color = '#ff9e64'
    },
    ['\19'] = {
        text = '󰩬 S-BLOCK',
        color = '#ff9e64'
    },
    c = {
        text = ' COMMAND',
        color = '#7dcfff'
    },
    t = {
        text = ' TERMINAL',
        color = '#73daca'
    }
}

local mode_strings = {}
local last_mode = nil

for mode, data in pairs(MODE_DISPLAY) do
    mode_strings[mode] = data.text
end

local STATUSBAR_JS = [[
  // Create or reuse the statusbar item
  if (!globalThis.modeStatusBar) {
    globalThis.modeStatusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  }
  
  const statusBar = globalThis.modeStatusBar;
  statusBar.text = args.text;
  statusBar.color = args.color;
  statusBar.command = {
    command: 'vscode-neovim.lua',
    title: 'Toggle Neovim Mode',
    arguments: [
      args.mode === 'n'
        ? "vim.cmd('startinsert')"
        : "vim.cmd('stopinsert')"
    ]
  };
  
  // Ensure visibility
  statusBar.show();
  
  // Setup automatic refresh mechanism
  if (!globalThis.statusBarRefreshInterval) {
    globalThis.statusBarRefreshInterval = setInterval(() => {
      if (statusBar && !statusBar.visible) {
        statusBar.show();
      }
    }, 1000); // Check every second
  }
]]

local STATUSBAR_DISPOSE_JS = [[
  if (globalThis.statusBarRefreshInterval) {
    clearInterval(globalThis.statusBarRefreshInterval);
    globalThis.statusBarRefreshInterval = null;
  }
  
  if (globalThis.modeStatusBar) {
    globalThis.modeStatusBar.dispose();
    globalThis.modeStatusBar = null;
  }
]]

function M.update_mode_display()
    local full_mode = vim.api.nvim_get_mode().mode
    local mode_key = full_mode:sub(1, 1)
    if mode_key == last_mode then
        pcall(vscode.eval, [[
      if (globalThis.modeStatusBar && !globalThis.modeStatusBar.visible) {
        globalThis.modeStatusBar.show();
      }
    ]], {
            timeout = 500
        })
        return
    end

    local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
    pcall(vscode.eval, STATUSBAR_JS, {
        timeout = 1000,
        args = {
            text = mode_strings[mode_key] or mode_strings.n,
            color = mode_data.color,
            mode = mode_key
        }
    })
    last_mode = mode_key
end

function M.set_command_mode()
    pcall(vscode.eval, STATUSBAR_JS, {
        timeout = 1000,
        args = {
            text = MODE_DISPLAY.c.text,
            color = MODE_DISPLAY.c.color,
            mode = 'c'
        }
    })
end

function M.force_refresh()
    M.update_mode_display()
end

function M.setup()
    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = M.update_mode_display
    })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = M.set_command_mode
    })

    vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "FocusGained", "VimResized"}, {
        callback = M.force_refresh
    })

    local timer = vim.loop.new_timer()
    timer:start(2000, 2000, vim.schedule_wrap(function()
        M.force_refresh()
    end))

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            timer:stop()
            timer:close()
            pcall(vscode.eval, STATUSBAR_DISPOSE_JS, {
                timeout = 500
            })
        end
    })

    M.update_mode_display()
end

-- No plugin definition for VSCode mode - it's handled through the VSCode API
-- M.plugins is intentionally nil in VSCode mode

return M
