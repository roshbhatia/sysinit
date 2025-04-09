return {
  {
    "mrjones2014/smart-splits.nvim",
    config = function()
      require("smart-splits").setup({
        ignored_buftypes = { "nofile", "quickfix", "prompt" },
        ignored_filetypes = { "NvimTree" },
        at_edge = "wrap",
        resize_mode = {
          silent = true,
          quit_key = "<ESC>",
          resize_keys = { "h", "j", "k", "l" },
        },
        multiplexer_integration = "wezterm", -- Explicitly set WezTerm integration
      })

      -- Keybindings for navigation
      vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move to left split" })
      vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move to below split" })
      vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move to above split" })
      vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move to right split" })

      -- Keybindings for resizing
      vim.keymap.set("n", "<leader>wh", require("smart-splits").resize_left, { desc = "Resize split left" })
      vim.keymap.set("n", "<leader>wj", require("smart-splits").resize_down, { desc = "Resize split down" })
      vim.keymap.set("n", "<leader>wk", require("smart-splits").resize_up, { desc = "Resize split up" })
      vim.keymap.set("n", "<leader>wl", require("smart-splits").resize_right, { desc = "Resize split right" })
    end,
  },
}
