-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/gelguy/wilder.nvim/refs/heads/master/doc/wilder.txt"
local M = {}

M.plugins = {{
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {"roxma/nvim-yarp", "roxma/vim-hug-neovim-rpc"},
    config = function()
        local wilder = require("wilder")
        wilder.setup({
            modes = {":", "/", "?"},
            next_key = "<Tab>",
            previous_key = "<S-Tab>",
            accept_key = "<Down>",
            reject_key = "<Up>"
        })

        local popupmenu_renderer = wilder.popupmenu_renderer(
            wilder.popupmenu_palette_theme({
                border = "rounded",
                empty_message = wilder.popupmenu_empty_message_with_spinner(),
                highlighter = wilder.basic_highlighter(),
                left = {" ", wilder.popupmenu_devicons(), wilder.popupmenu_buffer_flags({
                    flags = " a + ",
                    icons = {
                        ["+"] = "",
                        a = "",
                        h = ""
                    }
                })},
                right = {" ", wilder.popupmenu_scrollbar()},
                max_height = "75%",
                min_height = 0,
                prompt_position = "top",
                reverse = false,
                selected_item_index = 0
            }))

        local wildmenu_renderer = wilder.wildmenu_renderer({
            highlighter = wilder.basic_highlighter(),
            separator = " · ",
            left = {" ", wilder.wildmenu_spinner(), " "},
            right = {" ", wilder.wildmenu_index()},
            selected_item_index = 0
        })

        wilder.set_option("renderer", wilder.renderer_mux({
            [":"] = popupmenu_renderer,
            ["/"] = wildmenu_renderer,
            substitute = wildmenu_renderer
        }))
    end
}}

return M
