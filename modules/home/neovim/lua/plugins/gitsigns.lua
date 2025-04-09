return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { hl = "GitGutterAdd", text = "+" },
          change = { hl = "GitGutterChange", text = "~" },
          delete = { hl = "GitGutterDelete", text = "_" },
          topdelete = { hl = "GitGutterDelete", text = "‾" },
          changedelete = { hl = "GitGutterChange", text = "~" },
        },
        current_line_blame = true, -- Show blame inline
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local opts = { noremap = true, silent = true, buffer = bufnr }

          -- Keybindings for Git actions
          vim.keymap.set("n", "<leader>hs", gs.stage_hunk, opts)
          vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts)
          vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts)
          vim.keymap.set("n", "<leader>hb", gs.blame_line, opts)
        end,
      })
    end,
  },
}
