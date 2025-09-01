local M = {}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = vim.fn.argc(-1) == 0,
    cmd = {
      "TSUpdateSync",
      "TSUpdate",
      "TSInstall",
    },
    init = function(plugin)
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    keys = {
      {
        "<C-space>",
        desc = "Selection increment",
      },
      {
        "<bs>",
        desc = "Selection decrement",
        mode = "x",
      },
    },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "comment",
        "css",
        "csv",
        "cue",
        "diff",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "gotmpl",
        "gowork",
        "hcl",
        "helm",
        "html",
        "java",
        "javascript",
        "jinja",
        "jinja_inline",
        "jq",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "query",
        "regex",
        "ruby",
        "rust",
        "scss",
        "terraform",
        "toml",
        "tsv",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      sync_install = false,
      auto_install = true,
      ignore_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      rainbow = {
        enable = true,
        extended_mode = true,
        max_file_lines = nil,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]a"] = "@parameter.inner",
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]C"] = "@class.outer",
            ["]A"] = "@parameter.inner",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[c"] = "@class.outer",
            ["[a"] = "@parameter.inner",
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[C"] = "@class.outer",
            ["[A"] = "@parameter.inner",
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}

return M
