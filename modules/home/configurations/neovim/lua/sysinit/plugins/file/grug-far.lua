local M = {}

M.plugins = {
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({
        normalModeSearch = true,
      })
    end,
    keys = function()
      return {
        {
          "<leader>fg",
          function()
            require("grug-far").toggle_instance({
              instanceName = "far-global",
              staticTitle = "Global Search",
              prefills = {
                search = vim.fn.expand("<cword>"),
              },
            })
          end,
          desc = "Find: Grep",
        },
        {
          "<leader>fs",
          function()
            require("grug-far").toggle_instance({
              instanceName = "far-global",
              staticTitle = "Global Search",
              engine = "ast-grep",
              prefills = {
                search = vim.fn.expand("<cword>"),
              },
            })
          end,
          desc = "Find: Grep (ast-grep)",
        },
        {
          "<leader>fi",
          function()
            require("grug-far").toggle_instance({
              instanceName = "far-local",
              staticTitle = "Local Search",
              prefills = {
                paths = vim.fn.expand("%"),
                search = vim.fn.expand("<cword>"),
              },
            })
          end,
          desc = "Find: Grep in Buffer",
        },
      }
    end,
  },
}

return M
