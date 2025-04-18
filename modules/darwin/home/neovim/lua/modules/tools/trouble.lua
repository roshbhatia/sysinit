-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/docs/examples.md"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/trouble.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        icons = true,
        fold_open = "",
        fold_closed = "",
        signs = {
          error = "E",
          warning = "W",
          hint = "H",
          information = "I",
          other = "O",
        },
        use_diagnostic_signs = true,
      })
      local wk = require("which-key")
      wk.add({
        { "<leader>x", group = "Trouble", icon = { icon = "了", hl = "WhichKeyIconRed" } },
        { "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble", mode = "n" },
        { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics", mode = "n" },
        { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics", mode = "n" },
        { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List", mode = "n" },
        { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List", mode = "n" },
      })
    end,
  },
}

return M
