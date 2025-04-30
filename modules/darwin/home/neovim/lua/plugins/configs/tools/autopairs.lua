-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/windwp/nvim-autopairs/master/doc/nvim-autopairs.txt"
local M = {}

M.plugins = {{
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {"nvim-treesitter/nvim-treesitter"},
    config = function()
        require("nvim-autopairs").setup({
            check_ts = true,
            ts_config = {
                lua = {'string'},
                javascript = {'template_string'},
                typescript = {'template_string'},
                java = false
            },
            disable_filetype = {"TelescopePrompt", "vim"},
            enable_check_bracket_line = true,
            fast_wrap = {
                map = "<M-e>",
                chars = {"{", "[", "(", '"', "'"},
                pattern = [=[[%'%"%)%>%]%)%}%,]]=],
                offset = 0,
                end_key = "$",
                keys = "qwertyuiopzxcvbnmasdfghjkl",
                check_comma = true,
                highlight = "Search",
                highlight_grey = "Comment"
            }
        })
    end
}}

return M
