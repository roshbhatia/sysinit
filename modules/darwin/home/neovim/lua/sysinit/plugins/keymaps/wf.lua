-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Define plugins spec for lazy.nvim
M.plugins = {{
    "Cassin01/wf.nvim",
    config = function()
        require("wf").setup()

        local which_key = require("wf.builtin.which_key")

        -- Which Key
        vim.keymap.set("n", "<Leader>", -- mark(opts?: table) -> function
        -- opts?: option
        which_key({
            text_insert_in_advance = "<Leader>"
        }), {
            noremap = true,
            silent = true,
            desc = "[wf.nvim] which-key /"
        })
    end
}}

return M
