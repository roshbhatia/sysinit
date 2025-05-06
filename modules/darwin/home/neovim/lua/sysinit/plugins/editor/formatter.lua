-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/conform.nvim/master/doc/conform.txt"
local M = {}

M.plugins = {{
    "stevearc/conform.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
        formatters_by_ft = {
            lua = "stylua",
            python = "black",
            javascript = {"prettierd", "prettier"},
            typescript = {"prettierd", "prettier"},
            go = {"goimports", "gofmt"},
            json = {"prettierd", "prettier"},
            yaml = {"prettierd", "prettier"},
            markdown = {"prettierd", "prettier"},
            html = {"prettierd", "prettier"},
            css = {"prettierd", "prettier"},
            sh = "shfmt",
            bash = "shfmt",
            zsh = "shfmt",
            rust = "rustfmt",
            nix = "nixfmt"
        },
        stop_after_first = true,
        notify_on_error = false,
        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
            end
            return {
                timeout_ms = 500,
                lsp_fallback = true
            }
        end
    },
    init = function()
        local notify = require("notify")
        local function show_notification(message, level)
            notify(message, level, {
                title = "conform.nvim"
            })
        end

        vim.api.nvim_create_user_command("FormatToggle", function(args)
            local is_global = not args.bang
            if is_global then
                vim.g.disable_autoformat = not vim.g.disable_autoformat
                if vim.g.disable_autoformat then
                    show_notification("Autoformat-on-save disabled globally", "info")
                else
                    show_notification("Autoformat-on-save enabled globally", "info")
                end
            else
                vim.b.disable_autoformat = not vim.b.disable_autoformat
                if vim.b.disable_autoformat then
                    show_notification("Autoformat-on-save disabled for this buffer", "info")
                else
                    show_notification("Autoformat-on-save enabled for this buffer", "info")
                end
            end
        end, {
            desc = "Toggle autoformat-on-save",
            bang = true
        })
    end
}}

return M
