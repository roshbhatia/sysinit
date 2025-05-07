-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Group icons for different command categories
M.group_icons = {
    buffer = "󱅄", -- Buffer operations
    code = "󰘧", -- Code actions
    debug = "󰘧", -- Debugging 
    explorer = "󰒍", -- File explorer
    find = "󰀶", -- Find/search operations
    fold = "󰘧", -- Code folding
    git = "󰊢", -- Git operations
    lsp = "󰛖", -- LSP features
    llm = "󱚤", -- LLM/AI assistants
    notifications = "󰂚", -- Notifications
    problems = "󰗯", -- Problem/diagnostics
    search = "󰍉", -- Search features
    split = "󰃻", -- Window splitting
    tab = "󱅄" -- Tab operations
}

-- Store for all keybindings loaded from modules
M.keybindings_data = {}

-- Register a keymap group from a module
function M.register_group(key, name, bindings)
    if not M.keybindings_data[key] then
        M.keybindings_data[key] = {
            name = name,
            bindings = {}
        }
    end

    -- Add or update bindings in the group
    for _, binding in ipairs(bindings) do
        table.insert(M.keybindings_data[key].bindings, binding)
    end
end

-- Load all keymap group modules
function M.load_groups()
    local group_path = "sysinit.plugins.keymaps.groups."
    local groups = {"buffer", "code", "debug", "explorer", "fold", "git", "lsp", "llm", "notifications", "problems",
                    "search", "split", "terminal", "view", "window"}

    for _, group in ipairs(groups) do
        local ok, module = pcall(require, group_path .. group)
        if ok and module then
            if type(module.setup) == "function" then
                pcall(module.setup) -- Added pcall for error handling
            end
        end
    end

    return M.keybindings_data
end

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
