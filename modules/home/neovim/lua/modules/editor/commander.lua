local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "FeiyouG/commander.nvim",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("commander").setup({
        -- Commander configuration
        components = {
          "DESC",
          "KEYS",
          "CAT",
        },
        sort_by = {
          "CAT",
          "DESC",
        },
        integration = {
          telescope = {
            enable = true,
          },
          -- Lazy plugin manager keymaps
          lazy = {
            enable = true,
            set_plugin_name_as_cat = true,
          },
        },
      })
    end
  }
}

function M.setup()
  -- Register keymaps for commander
  vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commander<CR>", { noremap = true, silent = true, desc = "Commander" })
  
  -- Register verification steps
  verify.register_verification("commander", {
    {
      desc = "Commander Palette",
      command = "<leader>fc",
      expected = "Should open commander command palette"
    },
    {
      desc = "Commander Integration",
      command = ":Telescope commander",
      expected = "Should show commander palette with Telescope integration"
    }
  })
end

return M
