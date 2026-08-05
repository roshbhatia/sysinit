return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    config = function()
      -- New main branch: minimal setup, just set install_dir if desired
      require("nvim-treesitter").setup({})

      -- Install parsers (no-op if already installed)
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

      -- Enable treesitter highlighting and indentation per FileType
      -- (highlighting is now native to Neovim; nvim-treesitter just provides queries)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
        callback = function(args)
          local ft = args.match
          local buf = args.buf

          -- Skip markdown (use LSP/render-markdown instead)
          if ft == "markdown" or ft == "markdown_inline" then
            return
          end

          -- Disable for large files
          local line_count = vim.api.nvim_buf_line_count(buf)
          local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
          if line_count > 5000 or file_size > 2 * 1024 * 1024 then
            return
          end

          -- Disable for certain filetypes
          local disable_ft = { "log", "txt", "csv", "json" }
          if vim.tbl_contains(disable_ft, ft) then
            return
          end

          -- Start treesitter highlighting (built into Neovim 0.12+)
          pcall(vim.treesitter.start, buf)

          -- Enable treesitter-based indentation (experimental, from nvim-treesitter)
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Treesitter textobjects (still a separate plugin, compatible with main branch)
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
