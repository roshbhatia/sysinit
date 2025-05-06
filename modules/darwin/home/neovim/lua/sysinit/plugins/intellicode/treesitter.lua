-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-treesitter/nvim-treesitter/refs/heads/master/doc/nvim-treesitter.txt"
local M = {}

M.plugins = {{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {"nvim-treesitter/nvim-treesitter-textobjects"},
    opts = {
        ensure_installed = {"bash", "c", "cpp", "css", "diff", "dockerfile", "go", "html", "javascript", "json", "lua",
                            "markdown", "markdown_inline", "python", "regex", "rust", "terraform", "toml", "tsx",
                            "typescript", "vim", "yaml", "nix", "comment"},
        sync_install = true,
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false
        },
        indent = {
            enable = false
        },
        autopairs = {
            enable = false
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                    ["ab"] = "@block.outer",
                    ["ib"] = "@block.inner"
                }
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]f"] = "@function.outer",
                    ["]c"] = "@class.outer"
                },
                goto_next_end = {
                    ["]F"] = "@function.outer",
                    ["]C"] = "@class.outer"
                },
                goto_previous_start = {
                    ["[f"] = "@function.outer",
                    ["[c"] = "@class.outer"
                },
                goto_previous_end = {
                    ["[F"] = "@function.outer",
                    ["[C"] = "@class.outer"
                }
            }
        }
    },
    config = function(opts)
        require("nvim-treesitter").setup(opts)
    end
}}

return M
