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
    }
}}

return M
