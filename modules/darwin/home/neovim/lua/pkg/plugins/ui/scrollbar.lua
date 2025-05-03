local plugin_family = {}

M.plugins = {{
    "petertriho/nvim-scrollbar",
    lazy = false,
    config = function()
        require("scrollbar").setup({
            show = true,
            handle = {
                text = " ",
                color = "ScrollbarHandle",
                hide_if_all_visible = true
            },
            marks = {},
            excluded_filetypes = {"prompt", "TelescopePrompt", "noice", "NeoTree", "alpha"},
            autocmd = {
                render = {"BufWinEnter", "TabEnter", "TermEnter", "WinEnter", "CmdwinLeave", "TextChanged",
                          "VimResized", "WinScrolled"}
            }
        })
    end
}}

return plugin_family
