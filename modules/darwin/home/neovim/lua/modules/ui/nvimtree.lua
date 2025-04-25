-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-tree.lua/refs/heads/master/doc/nvim-tree-lua.txt"
local M = {}

M.plugins = {
  {
    "nvim-tree/nvim-tree.lua",
    event = "VeryLazy", -- Load lazily
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function()
      local status_ok, nvim_tree = pcall(require, "nvim-tree")
      if not status_ok then
        vim.notify("nvim-tree not found!", vim.log.levels.ERROR)
        return
      end

      -- disable netrw at the very start of your init.lua
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      nvim_tree.setup({
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true
        },
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })
      
      local wk = require("which-key")
      wk.add({
        { "<leader>e", group = "Explorer", icon = { icon = "🌲", hl = "WhichKeyIconGreen" } },
        { "<leader>ee", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree", mode = "n" },
        { "<leader>ef", "<cmd>NvimTreeFindFile<CR>", desc = "Find Current File", mode = "n" },
        { "<leader>er", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh NvimTree", mode = "n" },
        { "<leader>ec", "<cmd>NvimTreeCollapse<CR>", desc = "Collapse NvimTree", mode = "n" },
        { "<leader>ep", function() 
            local api = require("nvim-tree.api")
            local node = api.tree.get_node_under_cursor()
            local clipboard = require("nvim-tree.actions.clipboard.clipboard")
            clipboard.copy(node)
          end, 
          desc = "Copy Node Path", 
          mode = "n" 
        },
      })
    end,
  }
}

return M
