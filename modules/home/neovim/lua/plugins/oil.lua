return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true, -- Oil will take over directory buffers
        view_options = {
          show_hidden = true, -- Show hidden files
        },
        keymaps = {
          ["<CR>"] = "actions.select", -- Open file or directory
          ["<C-s>"] = { "actions.select", opts = { vertical = true } }, -- Open in vertical split
          ["<C-h>"] = { "actions.select", opts = { horizontal = true } }, -- Open in horizontal split
          ["<C-t>"] = { "actions.select", opts = { tab = true } }, -- Open in new tab
          ["<C-p>"] = "actions.preview", -- Preview file
          ["<C-c>"] = "actions.close", -- Close oil buffer
          ["<C-l>"] = "actions.refresh", -- Refresh oil buffer
          ["-"] = "actions.parent", -- Go to parent directory
          ["_"] = "actions.open_cwd", -- Open current working directory
          ["`"] = "actions.cd", -- Change directory
          ["~"] = { "actions.cd", opts = { scope = "tab" } }, -- Change directory for tab
          ["gs"] = "actions.change_sort", -- Change sort order
          ["gx"] = "actions.open_external", -- Open file externally
          ["g."] = "actions.toggle_hidden", -- Toggle hidden files
        },
        use_default_keymaps = false, -- Disable default keymaps
      })

      -- Keybinding to open Oil on the left side
      vim.keymap.set("n", "-", function()
        vim.cmd("vsplit | Oil")
      end, { desc = "Open parent directory with Oil on the left" })
    end,
  },
}
