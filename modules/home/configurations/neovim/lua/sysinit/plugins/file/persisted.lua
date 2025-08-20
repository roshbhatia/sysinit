local M = {}

M.plugins = {
  {
    "olimorris/persisted.nvim",
    event = "VimEnter",
    config = function()
      vim.o.sessionoptions = "curdir,folds,globals,tabpages,winpos,winsize"

      require("persisted").setup({
        save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/.." .. "/sessions/"),
        autoload = true,
        on_autoload_no_session = function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
      })
    end,
  },
}

return M
