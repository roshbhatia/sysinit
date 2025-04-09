local M = {}

M.plugins = {
  {
    "mrjones2014/legendary.nvim",
    dependencies = { "folke/which-key.nvim" },
    priority = 10000,
    lazy = false,
    opts = {
      extensions = {
        which_key = {
          auto_register = true,
          do_binding = true,
          use_groups = true,
        },
      },
      keymaps = {
        { "<leader>w", "<cmd>write<CR>", description = "Save File" },
        { "<leader>q", "<cmd>quit<CR>", description = "Quit" },
      },
    },
  },
}

function M.setup()
  -- Any additional setup after plugins are loaded
end

-- Register with core
require("core").register("keybindings", M)

return M
