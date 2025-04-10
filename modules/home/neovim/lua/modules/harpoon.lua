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
  -- Setup keymaps or additional configuration
  local mark = require("harpoon.mark")
  local ui = require("harpoon.ui")

  vim.keymap.set("n", "<leader>a", mark.add_file, { desc = "Harpoon: Add file" })
  vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu, { desc = "Harpoon: Toggle quick menu" })
end

return M
