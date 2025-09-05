local M = {}

M.plugins = {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    config = function()
      require("edgy").setup({
        keys = {
          ["<c-w>>"] = false,
          ["<c-w><lt>"] = false,
          ["<c-w>+"] = false,
          ["<c-w>-"] = false,
          ["<c-w>="] = false,
        },
        animate = {
          enabled = false,
        },
        options = {
          left = {
            size = 40,
          },
          right = {
            size = 60,
          },
        },
        left = {
          {
            title = " File Explorer",
            ft = "neo-tree",
            filter = function(buf)
              return vim.b[buf].neo_tree_source == "filesystem"
            end,
          },
        },
        bottom = {
          {
            title = " QuickFix",
            ft = "qf",
            size = { height = 0.3 },
          },
        },
        right = {
          {
            title = " Help",
            ft = "help",
            size = { height = 0.5 },
            filter = function(buf)
              return vim.bo[buf].buftype == "help"
            end,
          },
        },
        icons = {
          closed = "",
          open = "",
        },
        wo = {
          winbar = true,
          winfixwidth = true,
          winfixheight = false,
          winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
        },
      })
    end,
  },
}

return M
