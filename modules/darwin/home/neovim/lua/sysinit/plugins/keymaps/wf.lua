-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Define plugins spec for lazy.nvim
M.plugins = {{
    "Cassin01/wf.nvim",
    event = "VeryLazy",
    opts = function()
        local which_key = require("wf.builtin.which_key")
        local keybindings = M.load_groups and M.load_groups() or {}
        require("wf").setup({
            theme = "default",
            behavior = {
                skip_front_duplication = true,
                skip_back_duplication = true
            }
        })
        for prefix, group in pairs(keybindings) do
            for _, binding in ipairs(group.bindings) do
                if binding.neovim_cmd then
                    vim.keymap.set("n", "<leader>" .. prefix .. binding.key, binding.neovim_cmd, {
                        noremap = true,
                        silent = true,
                        desc = group.name .. ": " .. binding.desc
                    })
                end
            end
        end
        M.mark = require("wf.builtin.mark")
    end
}}

return M
