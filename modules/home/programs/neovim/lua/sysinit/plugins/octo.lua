return {
  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("octo").setup({
        default_merge_method = "rebase",
        default_delete_branch = true,
        picker = "snacks",
      })

      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = function()
      return {
        {
          "<leader>gr",
          "<CMD>Octo review<CR>",
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Review PR from current branch",
        },
        {
          "<leader>gfs",
          function()
            require("octo.utils").create_base_search_command({ include_current_repo = true })
          end,
          desc = "GitHub query",
        },
        {
          "<leader>gfp",
          "<CMD>Octo pr list<CR>",
          desc = "GitHub PRs",
        },
      }
    end,
  },
}
