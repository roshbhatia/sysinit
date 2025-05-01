-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/gelguy/wilder.nvim/refs/heads/master/doc/wilder.txt"
local M = {}

M.plugins = {{
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {"roxma/nvim-yarp", "roxma/vim-hug-neovim-rpc"},
    config = function()
        local wilder = require("wilder")
        wilder.setup({
            modes = {":", "/", "?"}
        })

        wilder.set_option('pipeline', {wilder.branch(wilder.cmdline_pipeline({
            fuzzy = 1,
            set_pcre2_pattern = 1
        }), wilder.vim_search_pipeline())})

        local popupmenu_renderer = wilder.popupmenu_renderer(
            wilder.popupmenu_palette_theme({ -- Changed from border_theme to palette_theme
                border = "none", -- No rounded borders
                max_height = "50%",
                min_height = 10, -- Increased min_height for more VSCode-like appearance
                prompt_position = "top",
                reverse = false,
                highlighter = {wilder.pcre2_highlighter(), wilder.basic_highlighter()},
                left = {" ", wilder.popupmenu_devicons()},
                right = {" ", wilder.popupmenu_scrollbar()},
                pumblend = 10 -- Add transparency
            }))

        -- Keep the wildmenu renderer as is
        local wildmenu_renderer = wilder.wildmenu_renderer({
            highlighter = {wilder.pcre2_highlighter(), wilder.basic_highlighter()},
            separator = " · ",
            left = {" ", wilder.wildmenu_spinner(), " "},
            right = {" ", wilder.wildmenu_index()}
        })

        wilder.set_option("renderer", wilder.renderer_mux({
            [":"] = popupmenu_renderer,
            ["/"] = wildmenu_renderer,
            substitute = wildmenu_renderer
        }))

        -- Set up keybindings manually to fix tab behavior
        -- This makes Tab select the first item if nothing is selected yet
        -- or move to the next item if something is already selected
        vim.api.nvim_set_keymap('c', '<Tab>',
            [[wilder#in_context() ? wilder#can_accept_completion() ? wilder#accept_completion() : wilder#next() : "\<Tab>"]],
            {
                noremap = true,
                expr = true
            })
        vim.api.nvim_set_keymap('c', '<S-Tab>',
            [[wilder#in_context() ? wilder#can_accept_completion() ? wilder#accept_completion() : wilder#previous() : "\<S-Tab>"]],
            {
                noremap = true,
                expr = true
            })

        -- Add Down and Up keys for accepting and rejecting completions
        vim.api.nvim_set_keymap('c', '<Down>',
            [[wilder#in_context() ? wilder#can_accept_completion() ? wilder#accept_completion() : wilder#next() : "\<Down>"]],
            {
                noremap = true,
                expr = true
            })
        vim.api.nvim_set_keymap('c', '<Up>',
            [[wilder#in_context() ? wilder#can_reject_completion() ? wilder#reject_completion() : "\<Up>" : "\<Up>"]], {
                noremap = true,
                expr = true
            })

        -- Extra mappings for accepting
        vim.api.nvim_set_keymap('c', '<CR>',
            [[wilder#in_context() ? wilder#can_accept_completion() ? wilder#accept_completion() : "\<CR>" : "\<CR>"]], {
                noremap = true,
                expr = true
            })
    end
}}

-- Separately load live-command.nvim to avoid conflicts
M.plugins[#M.plugins + 1] = {
    "smjonas/live-command.nvim",
    config = function()
        require("live-command").setup({
            commands = {
                Norm = {
                    cmd = "norm"
                }
            }
        })
    end
}

return M
