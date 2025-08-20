local M = {}

M.plugins = {
  {
    "Fildo7525/pretty_hover",
    opts = {
      max_width = math.floor(vim.o.columns * 0.7),
      max_height = math.floor(vim.o.lines * 0.3),
    },
    keys = function()
      return {
        {
          "<leader>ch",
          function()
            require("pretty_hover").hover()
          end,
          desc = "Hover documentation",
        },
        {
          "<S-k>",
          function()
            require("pretty_hover").hover()
          end,
          desc = "Hover documentation",
        },
      }
    end,
  },
}

return M
