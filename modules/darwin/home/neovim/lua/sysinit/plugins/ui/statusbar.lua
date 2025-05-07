local M = {}

M.plugins = {{
    dir = ".",
    name = "vscode-statusbar",
    lazy = false,
    enabled = function()
        return vim.g.vscode
    end,
    opts = {
        mode_icons = {
            n = {
                text = "󱄅 NORMAL",
                color = "#7aa2f7"
            },
            i = {
                text = " INSERT",
                color = "#9ece6a"
            },
            v = {
                text = "󰈈 VISUAL",
                color = "#bb9af7"
            },
            V = {
                text = "󱣾 V-LINE",
                color = "#bb9af7"
            },
            ["\22"] = {
                text = "󰮔 V-BLOCK",
                color = "#bb9af7"
            },
            R = {
                text = "󰛔 REPLACE",
                color = "#f7768e"
            },
            s = {
                text = "󰴱 SELECT",
                color = "#ff9e64"
            },
            S = {
                text = "󰫙 S-LINE",
                color = "#ff9e64"
            },
            ["\19"] = {
                text = "󰩬 S-BLOCK",
                color = "#ff9e64"
            },
            c = {
                text = " COMMAND",
                color = "#7dcfff"
            },
            t = {
                text = " TERMINAL",
                color = "#73daca"
            }
        }
    },
    config = function(_, opts)
        local vscode = require("vscode")
        local last_mode = nil

        local STATUSBAR_JS = [[
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
              statusBar.show();
            ]]

        local STATUSBAR_DISPOSE_JS = [[
              if (globalThis.modeStatusBar) {
                globalThis.modeStatusBar.dispose();
                globalThis.modeStatusBar = null;
              }
            ]]

        local function update_mode_display()
            local full_mode = vim.api.nvim_get_mode().mode
            local mode_key = full_mode:sub(1, 1)
            if mode_key == last_mode then
                return
            end

            local mode_data = opts.mode_icons[mode_key] or opts.mode_icons.n
            pcall(vscode.eval, STATUSBAR_JS, {
                timeout = 1000,
                args = {
                    text = mode_data.text,
                    color = mode_data.color,
                    mode = mode_key
                }
            })
            last_mode = mode_key
        end

        local function dispose_statusbar()
            pcall(vscode.eval, STATUSBAR_DISPOSE_JS, {
                timeout = 500
            })
        end

        vim.api.nvim_create_autocmd("ModeChanged", {
            callback = update_mode_display
        })
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = dispose_statusbar
        })

        update_mode_display()
    end
}, {
    "tamton-aquib/staline.nvim",
    lazy = false,
    enabled = function()
        return not vim.g.vscode
    end,
    opts = {
        sections = {
            left = {"mode", "branch", "file_name"},
            mid = {"lsp"},
            right = {"line_column"}
        }
    }
}}

return M
