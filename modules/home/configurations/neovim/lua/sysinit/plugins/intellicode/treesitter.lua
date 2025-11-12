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
      indent = {
        enable = true,
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

      -- Filetype mappings for templated YAML / kustomization with optional Go templating
      vim.filetype.add({
        extension = {
          ["yaml.tmpl"] = "gotmpl",
          ["yml.tmpl"] = "gotmpl",
        },
        filename = {
          ["kustomization.yaml"] = "yaml", -- default YAML unless template delimiters force gotmpl injection
          ["kustomization.yml"] = "yaml",
        },
        pattern = {
          [".*%.yaml%.tmpl"] = "gotmpl",
          [".*%.yml%.tmpl"] = "gotmpl",
        },
      })

      vim.g._ts_force_sync_parsing = true

      -- Auto-promote kustomization.yaml to gotmpl if delimiters present
      vim.api.nvim_create_autocmd({"BufReadPost","TextChanged","TextChangedI"}, {
        pattern = {"kustomization.yaml","kustomization.yml"},
        callback = function(ev)
          local bufnr = ev.buf
          if vim.bo[bufnr].filetype ~= "yaml" then return end
          local first_1k = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, math.min(1000, vim.api.nvim_buf_line_count(bufnr)), false), "\n")
          if first_1k:find("{{") then
            vim.bo[bufnr].filetype = "gotmpl"
          end
        end,
      })
    end,
  },
}

return M
