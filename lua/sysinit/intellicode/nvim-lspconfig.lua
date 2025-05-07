local M = {}

M.plugins = {{
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    lazy = true,
    config = function()
        -- LSP Configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>c", "Code", {
            {"d", vim.lsp.buf.definition, "Go to Definition"},
            {"r", vim.lsp.buf.references, "Find References"},
            {"a", vim.lsp.buf.code_action, "Code Action"},
            {"n", vim.lsp.buf.rename, "Rename"},
            {"f", vim.lsp.buf.format, "Format Document"},
            {"h", vim.lsp.buf.hover, "Hover Documentation"},
            {"s", vim.lsp.buf.signature_help, "Signature Help"},
        })
        
        -- Autocommands for LSP
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Enable completion triggered by <c-x><c-o>
                vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
            end,
        })
    end
}}

return M