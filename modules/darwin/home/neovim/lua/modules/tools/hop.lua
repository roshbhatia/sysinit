-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/hadronized/hop.nvim/refs/heads/master/doc/hop.txt"
local M = {}

M.plugins = {{
    'phaazon/hop.nvim',
    branch = 'v2',
    config = function()
        local hop = require('hop')
        local directions = require('hop.hint').HintDirection

        hop.setup({
            keys = 'etovxqpdygfblzhckisuran'
        })
    end
}}

return M
