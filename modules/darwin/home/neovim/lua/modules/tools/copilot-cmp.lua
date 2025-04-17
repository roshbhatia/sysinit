-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/zbirenbaum/copilot-cmp/master/README.md"
local M = {}

M.plugins = {
  {
    "zbirenbaum/copilot-cmp",
    lazy = false,
    dependencies = {
      "zbirenbaum/copilot.lua",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      -- Setup copilot-cmp
      require("copilot_cmp").setup({
        event = { "InsertEnter", "LspAttach" },
        fix_pairs = true,
      })
      
      -- Setup base copilot.lua (required for copilot-cmp)
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
        filetypes = {
          ["*"] = true,
          ["help"] = false,
          ["gitcommit"] = false,
          ["gitrebase"] = false,
          ["hgcommit"] = false,
          ["svn"] = false,
          ["cvs"] = false,
        },
      })
      
      -- Add custom highlighting for copilot items
      vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
    end
  }
}

return M