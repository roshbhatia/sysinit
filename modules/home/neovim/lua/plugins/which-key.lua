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
        { "<leader>e", group = "File Explorer" },
        { "<leader>ee", "<cmd>Oil<CR>", desc = "Open Oil File Explorer" },
        { "<leader>en", "<cmd>Oil<CR>", desc = "Open Parent Directory" },

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

      -- Add keybindings for legendary.nvim
      wk.register({
        ["<leader>"] = {
          f = {
            name = "Find",
            f = { ":Telescope find_files<CR>", "Find files" },
            g = { ":Telescope live_grep<CR>", "Live grep" },
            b = { ":Telescope buffers<CR>", "Find buffers" },
            h = { ":Telescope help_tags<CR>", "Find help" },
          },
          l = { ":Legendary<CR>", "Command Palette" },
        },
      })

      -- Add keybindings for neominimap.nvim
      wk.register({
        ["<leader>n"] = {
          name = "Neominimap",
          m = { "<cmd>Neominimap toggle<CR>", "Toggle global minimap" },
          o = { "<cmd>Neominimap on<CR>", "Enable global minimap" },
          c = { "<cmd>Neominimap off<CR>", "Disable global minimap" },
          r = { "<cmd>Neominimap refresh<CR>", "Refresh global minimap" },
        },
      })
    end,
  },
}