-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {{
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    event = "BufReadPost",
    config = function()
        vim.opt.wrap = false
        vim.opt.sidescrolloff = 36

        require("neominimap").setup({
            auto_enable = false,

            -- Set floating window layout
            layout = "float",

            -- Configure the float window to match VSCode behavior
            float = {
                minimap_width = 20,
                -- Add transparency
                opacity = 0.8,
                -- Position the float window on the right side
                position = "right",
                -- Add hover detection
                show_on_hover = true,
                -- Set a small delay before showing on hover
                hover_delay = 100
            },

            -- Configure highlight groups to support transparency
            hl = {
                Normal = {
                    bg = "NONE"
                },
                NormalFloat = {
                    bg = "NONE"
                },
                FloatBorder = {
                    bg = "NONE"
                }
            }
        })
    end
}}

return M
