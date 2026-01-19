return {
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({
        showEngineInfo = false,
        normalModeSearch = true,
        windowCreationCommand = "aboveleft vsplit | wincmd H | silent! Neotree close",
        openTargetWindow = {
          preferredLocation = "right",
        },
        searchOnInsertLeave = true,
        resultLocation = {
          showNumberLabel = false,
        },
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
          desc = "Grep",
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
          desc = "Grep in buffer",
        },
      }
    end,
  },
}
