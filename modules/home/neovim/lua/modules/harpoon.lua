local M = {}

M.plugins = {
  {
    'ThePrimeagen/harpoon',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require("harpoon").setup({
        -- Add any specific Harpoon configuration here
      })
    end
  }
}

function M.setup()
  -- Which-key bindings using V3 format
  local mark = require("harpoon.mark")
  local ui = require("harpoon.ui")
  local wk = require("which-key")
  
  wk.add({
    { "<leader>a", function() mark.add_file() end, desc = "Harpoon: Add file" },
    { "<C-e>", function() ui.toggle_quick_menu() end, desc = "Harpoon: Toggle quick menu" }
  })
end

return M
