local M = {}

M.plugins = {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      integrations = {
        icon = "nvim-web-devicons",
      },
      views = {
        finder = {
          delete_to_trash = true,
          mappings = {
            ["<localleader>t"] = "SelectTab",
            ["v"] = "SelectVSplit",
            ["s"] = "SelectSplit",
            ["<loaclleader>p"] = "GotoParent",
            ["<localleader>c"] = "GotoCwd",
            ["<localleader>n"] = "GotoNode",
            ["zM"] = "CollapseAll",
            ["zc"] = "CollapseNode",
          },
        },
        win = {
          win_opts = {
            cursorline = true,
          },
        },
      },
    },
  },
}

return M
