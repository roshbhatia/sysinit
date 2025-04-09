return {
  {
    "github/copilot.vim",
    lazy = false,
  },
  {
    "simrat39/symbols-outline.nvim",
    config = function()
      require("symbols-outline").setup({
        position = "right",
        width = 30,
      })
    end,
  },
  {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    config = function()
      vim.g.neominimap = {
        auto_enable = true,
        layout = "split",
        split = {
          direction = "right",
          minimap_width = 20,
        },
        treesitter = { enabled = true },
        git = { enabled = true },
        diagnostic = { enabled = true },
      }
    end,
  },
  -- Keybinding to toggle the right panel
  {
    "custom/right-panel-toggle",
    config = function()
      vim.keymap.set("n", "<leader>r", function()
        if vim.fn.bufname() == "symbols-outline" or vim.fn.bufname() == "neominimap" then
          vim.cmd("close")
        else
          vim.cmd("vsplit | SymbolsOutline")
          vim.cmd("vsplit | Neominimap")
        end
      end, { desc = "Toggle Right Panel" })
    end,
  },
}
