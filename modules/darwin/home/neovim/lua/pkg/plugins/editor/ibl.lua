-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/lukas-reineke/indent-blankline.nvim/refs/heads/master/doc/indent_blankline.txt"
local M = {}

M.plugins = {{
    "lukas-reineke/indent-blankline.nvim",
    commit = "005b56001b2cb30bfa61b7986bc50657816ba4ba",
    main = "ibl",
    lazy = true,
    priority = 950,
    config = function()
        local hooks = require("ibl.hooks")

        require("ibl").setup({
            enabled = true,
            debounce = 200,

            indent = {
                char = "▏",
                tab_char = "▏",
                highlight = "IblIndent",
                smart_indent_cap = true,
                priority = 1
            },

            whitespace = {
                highlight = "IblWhitespace",
                remove_blankline_trail = true
            },

            scope = {
                enabled = true,
                char = "▏",
                show_start = true,
                show_end = true,
                show_exact_scope = false,
                injected_languages = true,
                highlight = "IblScope",
                priority = 1024
            },

            exclude = {
                filetypes = {"lspinfo", "packer", "checkhealth", "help", "man", "gitcommit", "TelescopePrompt",
                             "TelescopeResults", "dashboard", "NeoTree", "lazy", ""},
                buftypes = {"terminal", "nofile", "quickfix", "prompt"}
            }
        })

        local has_rainbow_delimiters, _ = pcall(require, "rainbow-delimiters")
        if has_rainbow_delimiters then
            local highlight = {"RainbowDelimiterRed", "RainbowDelimiterYellow", "RainbowDelimiterBlue",
                               "RainbowDelimiterOrange", "RainbowDelimiterGreen", "RainbowDelimiterViolet",
                               "RainbowDelimiterCyan"}

            require("ibl").setup({
                scope = {
                    highlight = highlight
                }
            })

            hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
        end

        hooks.register(hooks.type.SKIP_LINE, hooks.builtin.skip_preproc_lines)
    end
}}

return M

