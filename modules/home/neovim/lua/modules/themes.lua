local M = {}

M.plugins = {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end
  }
}

function M.setup()
  -- Theme-specific setup
end

return M
