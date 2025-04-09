return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
            },
          },
        },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          local opts = { noremap = true, silent = true, buffer = bufnr }

          -- Key mappings for nvim-tree
          vim.keymap.set("n", "<C-e>", api.node.open.edit, opts)
          vim.keymap.set("n", "<C-r>", api.tree.reload, opts)
        end,
      })

      -- Keybinding to toggle nvim-tree
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "Toggle File Explorer" })
    end,
  },
}
