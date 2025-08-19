local M = {}

M.plugins = {
  {
    "olimorris/persisted.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    event = "BufReadPre",
    config = function()
      vim.o.sessionoptions = "curdir,folds,globals,tabpages,winpos,winsize"

      require("persisted").setup({
        save_dir = vim.fn.stdpath("data") .. "/sessions/",
        use_git_branch = true,
        autoload = false,
        should_save = function()
          return vim.bo.filetype ~= "alpha"
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          local argc = vim.fn.argc()
          local argv = vim.v.argv
          local persisted = require("persisted")

          if argc == 1 and argv[2] == "." then
            persisted.load({ last = true })
            vim.defer_fn(function()
              require("telescope.builtin").find_files({ hidden = true })
            end, 100)
          else
            persisted.autoload({ force = true })
          end
        end,
      })
    end,
  },
}

return M
