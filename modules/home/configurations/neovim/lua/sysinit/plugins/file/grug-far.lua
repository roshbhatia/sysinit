local M = {}

M.plugins = {
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({
        normalModeSearch = true,
        engines = {
          ripgrep = {
            extraArgs = "--hidden --iglob '!.cache' --iglob '!.flac' --iglob '!.jpeg' --iglob '!.jpg' --iglob '!.m4b' --iglob '!.m4v' --iglob '!.mp3' --iglob '!.o' --iglob '!.png' --iglob '!.wav' --iglob '!**/dist' --iglob '!.bin' --iglob '!.claude' --iglob '!.cursor' --iglob '!.direnv' --iglob '!.dist' --iglob '!.git' --iglob '!.git-crypt' --iglob '!.githooks' --iglob '!.out' --iglob '!.serena' --iglob '!.venv' --iglob '!bin' --iglob '!development/render' --iglob '!development/validate' --iglob '!dist' --iglob '!models' --iglob '!node_modules' --iglob '!out' --iglob '!target'",
          },
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
          mode = { "n" },
          desc = "Find: Grep",
        },
        {
          "<leader>fg",
          function()
            require("grug-far").with_visual_selection(function(instance)
              instance:toggle_instance({
                instanceName = "far-global",
                staticTitle = "Global Search",
              })
            end)
          end,
          mode = { "v" },
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
