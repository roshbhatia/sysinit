return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = {
      animate = {
        enabled = false,
      },
      keys = {
        ["q"] = function(win)
          win:close()
        end,
      },
      left = {
        {
          title = "Neo-Tree",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          size = { width = 30 },
        },
        {
          ft = "trouble",
          size = { width = 30 },
          ---@diagnostic disable-next-line: unused-local
          filter = function(buf, win)
            return vim.w[win].trouble_type == nil or vim.w[win].trouble_type == ""
          end,
        },
        {
          ft = "grug-far",
          size = { width = 40 },
        },
        {
          ft = "qf",
          title = "QuickFix",
          size = { width = 10 },
        },
      },
    },
  },
}
