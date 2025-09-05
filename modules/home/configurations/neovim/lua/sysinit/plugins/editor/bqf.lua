local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    config = function()
      require("bqf").setup({
        func_map = {
          fzffilter = "<localleader>f",
          ptoggleauto = "",
          ptoggleitem = "",
          ptogglemode = "",
          split = "<localleader>s",
          tabc = "",
          vsplit = "<localleader>v",
        },
        preview = {
          winblend = 0,
        },
        show_title = {
          description = [[Show the window title]],
          default = false,
        },
      })
    end,
  },
}

return M
