return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      animate = {
        enabled = false,
      },
      exit_when_last = true,
      keys = {
        ["q"] = function(win)
          win:hide()
        end,
        ["<c-q>"] = false,
        ["Q"] = false,
        ["]w"] = false,
        ["[w"] = false,
        ["]W"] = false,
        ["[W"] = false,
        ["<c-w>>"] = false,
        ["<c-w><lt>"] = false,
        ["<c-w>+"] = false,
        ["<c-w>-"] = false,
        ["<c-w>="] = false,
      },
      left = {
        {
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          size = { width = 0.2625 },
        },
        {
          ft = "trouble",
          size = { width = 0.2625 },
          ---@diagnostic disable-next-line: unused-local
          filter = function(buf, win)
            return vim.w[win].trouble_type == nil or vim.w[win].trouble_type == ""
          end,
        },
        {
          ft = "grug-far",
          size = { width = 0.4 },
        },
      },
      right = {
        {
          ft = "help",
          size = { width = 0.5 },
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
      },
    },
  },
}
