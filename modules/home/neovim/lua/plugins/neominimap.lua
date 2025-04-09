return {
  {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    lazy = false,
    keys = {
      { "<leader>nm", "<cmd>Neominimap toggle<CR>", desc = "Toggle global minimap" },
      { "<leader>no", "<cmd>Neominimap on<CR>", desc = "Enable global minimap" },
      { "<leader>nc", "<cmd>Neominimap off<CR>", desc = "Disable global minimap" },
      { "<leader>nr", "<cmd>Neominimap refresh<CR>", desc = "Refresh global minimap" },
    },
    config = function()
      vim.g.neominimap = {
        auto_enable = true,
        layout = "float", -- Use floating minimap
        float = {
          minimap_width = 20,
          window_border = "rounded",
        },
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.WARN,
        },
        git = {
          enabled = true,
        },
        treesitter = {
          enabled = true,
        },
      }
    end,
  },
}
