local M = {}

M.plugins = {
  -- Plugins related to UI layout
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true
  }
}

function M.setup()
  -- Layout-specific setup
end

return M
