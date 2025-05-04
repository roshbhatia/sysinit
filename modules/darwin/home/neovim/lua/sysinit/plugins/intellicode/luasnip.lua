local M = {}

M.plugins = {{
    "L3MON4D3/LuaSnip",
    lazy = true,
    event = "InsertEnter",
    version = "v2.*",
    build = "make install_jsregexp",
    config = function()
        local luasnip = require("luasnip")
        require("luasnip/loaders/from_vscode").lazy_load()
    end
}}

return M
