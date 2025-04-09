local M = {}

M.plugins = {
  {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
    dependencies = { "folke/which-key.nvim" },
    opts = {
      extensions = {
        which_key = {
          auto_register = true,
          do_binding = true,
          use_groups = true,
        },
        lazy_nvim = true,
      },
      keymaps = {
        -- Basic operations
        { "<leader>w", "<cmd>write<CR>", description = "Save File" },
        { "<leader>q", "<cmd>quit<CR>", description = "Quit" },
        
        -- Panel groups
        { "<leader>e", group = "Explorer" },
        { "<leader>r", group = "Right Panel" },
        { "<leader>w", group = "Window" },
      },
    },
  },
}

-- Add verification steps
local verify = require("core.verify")
verify.register_verification("keybindings", {
  {
    desc = "Check Legendary integration",
    command = ":Legendary",
    expected = "Should open command palette with all registered keymaps",
  },
  {
    desc = "Verify Which-Key integration",
    command = "Press <leader> and wait",
    expected = "Should show which-key popup with all registered keymaps",
  },
  {
    desc = "Test basic keymaps",
    command = "<leader>w",
    expected = "Should save the current file",
  },
})

function M.setup()
  -- Any additional setup after plugins are loaded
end

-- Register with core
require("core").register("keybindings", M)

return M
