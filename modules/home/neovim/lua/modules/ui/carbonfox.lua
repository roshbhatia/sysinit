local verify = require("core.verify")

-- sysinit.nvim.readme-url="https://raw.githubusercontent.com/EdenEast/nightfox.nvim/main/README.md"

local M = {}

M.plugins = {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = {
          styles = {
            comments = "italic",
            keywords = "bold",
            types = "italic,bold",
          },
        },
      })
      vim.cmd("colorscheme carbonfox")
    end
  }
}

function M.setup()
  local commander = require("commander")

  -- Register theme commands with commander
  commander.add({
    {
      desc = "Set Carbonfox Theme",
      cmd = "<cmd>colorscheme carbonfox<CR>",
      keys = { "n", "<leader>tc" },
      cat = "Theme"
    },
    {
      desc = "Toggle Dark/Light Theme",
      cmd = function()
        if vim.o.background == "dark" then
          vim.o.background = "light"
        else
          vim.o.background = "dark"
        end
      end,
      keys = { "n", "<leader>tt" },
      cat = "Theme"
    }
  })

  -- Register verification steps
  verify.register_verification("carbonfox", {
    {
      desc = "Carbonfox Theme",
      command = ":colorscheme",
      expected = "Should show carbonfox as active colorscheme"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Theme",
      expected = "Should show Theme commands in Commander palette"
    }
  })
end

return M