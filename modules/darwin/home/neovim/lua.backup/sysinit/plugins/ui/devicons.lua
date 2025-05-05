-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-web-devicons/refs/heads/master/README.md"
local M = {}

M.plugins = {{
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    opts = {
        override = {
            default_icon = {
                icon = "",
                color = "#6d8086",
                name = "Default"
            },
            nix = {
                icon = "",
                color = "#7ebae4",
                name = "Nix"
            }
        },
        default = true,
        strict = true,
        color_icons = true
    }
}}
return M
