return {
  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          spelling = { enabled = true },
        },
        win = { border = "rounded" },
      })

      -- Add keybindings for wezterm.nvim
      wk.register({
        ["<leader>w"] = {
          name = "WezTerm",
          l = { "<cmd>lua require('wezterm').split_pane.horizontal({ right = true, percent = 20, program = { 'nvim' } })<CR>", "Open right pane" },
          m = { "<cmd>lua require('wezterm').split_pane.horizontal({ left = true, percent = 60, program = { 'nvim' } })<CR>", "Open middle pane" },
          e = { "<cmd>lua require('wezterm').split_pane.horizontal({ left = true, percent = 20, program = { 'wezterm' } })<CR>", "Open left pane" },
        },
      })
    end,
  },
}