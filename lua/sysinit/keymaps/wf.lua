-- keymaps/wf.lua
local M = {}

M.plugins = {{
    "Cassin01/wf.nvim", -- the upstream project
    lazy = false,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        local which_key = require("wf.builtin.which_key")
        
        -- Set up global key group prefixes
        if _G.__key_prefixes == nil then
            _G.__key_prefixes = {
                n = {}, -- normal mode
                i = {}, -- insert mode
                v = {}, -- visual mode
            }
        end

        -- Register leader key groups
        local key_groups = {
            ["<leader>a"] = "[AI]",           -- AI/Copilot
            ["<leader>c"] = "[Code]",         -- LSP/code actions
            ["<leader>d"] = "[Debug]",        -- Debugging
            ["<leader>f"] = "[Find/File]",    -- File operations/Telescope
            ["<leader>g"] = "[Git]",          -- Git operations
            ["<leader>gb"] = "[Git Blame]",   -- Git blame
            ["<leader>gd"] = "[Git Diff]",    -- Git diff
            ["<leader>go"] = "[Git Octo]",    -- GitHub operations
            ["<leader>m"] = "[Markdown/Map]", -- Markdown/Minimap
            ["<leader>o"] = "[Outline]",      -- Code outline
            ["<leader>t"] = "[Terminal]",     -- Terminal
            ["<leader>x"] = "[Diagnostics]",  -- Diagnostics/Trouble
        }

        -- Add key groups to global prefixes
        for prefix, desc in pairs(key_groups) do
            _G.__key_prefixes.n[prefix] = desc
        end

        -- Set up which key
        vim.keymap.set(
            "n",
            "<Leader>",
            which_key({ text_insert_in_advance = "<Leader>", key_group_dict = _G.__key_prefixes.n }),
            { noremap = true, silent = true, desc = "[wf.nvim] which-key" }
        )

        -- Configure wf.nvim
        require("wf").setup({
            theme = "default", -- "default", "space", or "chad"
            behavior = {
                skip_front_duplication = true,
                skip_back_duplication = true,
            },
        })
    end
}}

-- Helper function to create keymaps for a specific module
M.register_keymaps = function(prefix, group_name, keymaps)
    local sign = "[" .. group_name .. "] "
    
    -- Register the prefix with the group name if it doesn't already exist
    if not _G.__key_prefixes.n[prefix] then
        _G.__key_prefixes.n[prefix] = sign
    end
    
    for _, keymap in ipairs(keymaps) do
        local key, cmd, desc, opt = unpack(keymap)
        local _opt = opt or {}
        _opt["desc"] = sign .. desc
        _opt["noremap"] = true
        
        vim.keymap.set("n", prefix .. key, cmd, _opt)
    end
end

return M