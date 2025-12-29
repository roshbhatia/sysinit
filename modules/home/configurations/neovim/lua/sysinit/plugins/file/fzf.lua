local M = {}

M.plugins = {
  {
    "ibhagwan/fzf-lua",
    config = function()
      require("fzf-lua").setup({ "fzf-vim" })
    end,
  },
}

return M
