return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      require("nvim-treesitter").install({
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
        "html",
        "java",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
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
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
        callback = function(args)
          local ft = args.match
          local buf = args.buf

          if ft == "markdown" or ft == "markdown_inline" then
            return
          end

          local line_count = vim.api.nvim_buf_line_count(buf)
          local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
          if line_count > 5000 or file_size > 2 * 1024 * 1024 then
            return
          end

          local disable_ft = { "log", "txt", "csv", "json" }
          if vim.tbl_contains(disable_ft, ft) then
            return
          end

          pcall(vim.treesitter.start, buf)

          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
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
      })
    end,
  },
}
