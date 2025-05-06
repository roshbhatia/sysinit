local M = {}

M.plugins = {{
    "rcarriga/nvim-notify",
    lazy = false,
    opts = {
        background_colour = "#000000",
        render = "wrapped-compact",
        timeout = 2000,
        stages = "fade_in_slide_out",
        max_width = 50,
        max_height = 10,
        fps = 60,
        on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        end
    }
}}

return M
