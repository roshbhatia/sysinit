local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    opts = {
      preview = {
        winblend = 0,
      },
      filter = {
        fzf = {
          action_for = {
            ["<localleader>qt"] = {
              description = [[Press <localleader>qt to open up the item in a new tab]],
              default = "tabedit",
            },
            ["<localleader>qv"] = {
              description = [[Press <localleader>qv to open up the item in a new vertical split]],
              default = "vsplit",
            },
            ["<localleader>qs"] = {
              description = [[Press <localleader>qs to open up the item in a new horizontal split]],
              default = "split",
            },
            ["<localleader>qq"] = {
              description = [[Press <localleader>qq to toggle sign for the selected items]],
              default = "signtoggle",
            },
            ["q"] = {
              description = [[Press q to close quickfix window and abort fzf]],
              default = "closeall",
            },
          },
        },
      },
    },
  },
}

return M
