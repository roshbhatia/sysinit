-- Helper to handle lazy.nvim window closing
return {
  {
    "folke/lazy.nvim",
    event = "VeryLazy",
    keys = {
      { "<ESC>", "<cmd>close<CR>", ft = "lazy", desc = "Close lazy UI" },
      { "q", "<cmd>close<CR>", ft = "lazy", desc = "Close lazy UI" },
    },
    opts = {
      ui = {
        -- This enables the special key handling for the lazy UI
        custom_keys = {
          ["<ESC>"] = function(plugin)
            require("lazy.view.config").close()
            return true
          end,
          ["q"] = function(plugin)
            require("lazy.view.config").close()
            return true
          end,
        },
      },
    },
  },
}
