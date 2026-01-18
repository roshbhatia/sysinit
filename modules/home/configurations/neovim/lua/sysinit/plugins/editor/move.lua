return {
  {
    "nvim-mini/mini.nvim",
    event = "CursorMoved",
    version = "*",
    config = function()
      require("mini.move").setup({
        mappings = {
          left = "<S-h>",
          right = "<S-l>",
          down = "<S-j>",
          up = "<S-k>",
        },
        options = {
          reindent_linewise = true,
        },
      })
    end,
  },
}
