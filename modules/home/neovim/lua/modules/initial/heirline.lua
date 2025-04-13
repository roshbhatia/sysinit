local M = {}

M.plugins = {
  {
    'rebelot/heirline.nvim',
    dependencies = { 
      'nvim-tree/nvim-web-devicons',
      'lewis6991/gitsigns.nvim'
    },
    config = function()
      require("heirline").setup({
        -- Add your Heirline configuration here
      })
    end
  }
}

function M.setup()
  -- Additional setup logic if needed
end

return M
