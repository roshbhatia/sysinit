return {
  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          spelling = { enabled = true },
        },
        win = { -- Updated from `window` to `win`
          border = "rounded",
        },
      })

      -- Update to the new which-key spec format
      wk.add({
        { "<leader>e", group = "File Tree" },
        { "<leader>ee", "<cmd>NvimTreeToggle<CR>", desc = "Toggle File Tree" },
        { "<leader>en", "<cmd>NvimTreeFindFile<CR>", desc = "Find File in Tree" },
        { "<leader>er", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh File Tree" },

        { "<leader>x", group = "Diagnostics" },
        { "<leader>xx", "<cmd>TroubleToggle<CR>", desc = "Toggle Trouble" },
        { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "Workspace Diagnostics" },
        { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>", desc = "Document Diagnostics" },
        { "<leader>xl", "<cmd>TroubleToggle loclist<CR>", desc = "Location List" },
        { "<leader>xq", "<cmd>TroubleToggle quickfix<CR>", desc = "Quickfix List" },

        { "<leader>a", "ggVG", desc = "Select All" },
        { "<leader>s", ":w<CR>", desc = "Save File" },
        { "<leader>c", '"+y', desc = "Copy to Clipboard" },
        { "<leader>x", '"+d', desc = "Cut to Clipboard" },
        { "<leader>v", '"+p', desc = "Paste from Clipboard" },
        { "<leader>9", "<cmd>Themery<CR>", desc = "Switch Theme" }, -- Theme switching
      })
    end,
  },
}