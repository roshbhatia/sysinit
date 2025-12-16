local M = {}

M.plugins = {
  {
    "yaocccc/nvim-foldsign",
    config = function()
      require("nvim-foldsign").setup({
        offset = -3,
        foldsigns = {
          open = "*", -- mark the beginning of a fold
          close = "-", -- show a closed fold
          seps = { "│", "┃" }, -- open fold middle marker
        },
        enabled = true,
      })
    end,
  },
}
return M
