local M = {}

M.plugins = {{
    "tamton-aquib/staline.nvim",
    config = function()
        require("staline").setup {
            sections = {
                left = {'  ', 'mode', ' ', 'branch', ' ', 'lsp'},
                mid = {},
                right = {'file_name', 'line_column'}
            },
            defaults = {
                true_colors = true,
                line_column = " [%l/%L] :%c  ",
                branch_symbol = " "
            }
        }
    end
}}

return M
