local M = {}

M.plugins = {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Flyer",
    opts = {
      integrations = {
        icon = "nvim_web_devicons",
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
    keys = function()
      return {
        {
          "<leader>et",
          function()
            vim.cmd(":Flyer")
          end,
          desc = "Toggle explorer tree",
        },
      }
    end,
  },
}

return M
