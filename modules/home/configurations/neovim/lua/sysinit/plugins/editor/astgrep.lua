local M = {}

M.plugins = {
  {
    "0xstepit/ast-grep.nvim",
    cmd = { "AstGrep", "AstGrepSearch", "AstGrepReplace" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("ast-grep").setup({
        command = "ast-grep",

        file_patterns = {
          "*.ts",
          "*.tsx",
          "*.js",
          "*.jsx",
          "*.go",
          "*.py",
          "*.lua",
          "*.nix",
          "*.rs",
          "*.c",
          "*.cpp",
          "*.java",
        },

        search_opts = {
          case_sensitive = false,
          follow_symlinks = true,
          hidden = false,
        },

        telescope = {
          enabled = true,
          theme = "ivy",
        },
      })
    end,
    keys = {
      {
        "<leader>fS",
        function()
          require("ast-grep").search_in_files()
        end,
        desc = "Find structural pattern in files",
      },
      {
        "<leader>fR",
        function()
          require("ast-grep").replace()
        end,
        desc = "Replace structural pattern (AST)",
        mode = { "n", "v" },
      },
    },
  },
}

return M
