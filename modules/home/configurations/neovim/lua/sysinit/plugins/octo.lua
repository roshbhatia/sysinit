return {
  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "Octo" },
    config = function()
      require("octo").setup({
        use_local_fs = true,
        enable_builtin = true,
        default_merge_method = "squash",
        default_delete_branch = true,
        picker = "snacks",
      })

      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = function()
      return {
        {
          "<leader>grr",
          "<CMD>Octo review<CR>",
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Review PR from current branch",
        },
      }
    end,
  },
}
