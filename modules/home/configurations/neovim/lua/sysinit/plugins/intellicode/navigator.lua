local M = {}

M.plugins = {
  {
    "ray-x/navigator.lua",
    event = { "LspAttach" },
	  dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
      "ray-x/guihua.lua",
	    "folke/trouble.nvim"
    },
    config = function()
      require("navigator").setup({
        icons = {
          code_action_icon = "󰘧",
          diagnostic_head = """,
		      diagnostic_head_severity_1 = "󱢇"
        },
        keymaps = {
          { key = "<leader>ca", func = "code_action", desc = "Code Action" },
          { key = "<leader>cr", func = "rename", desc = "Rename" },
          { key = "<leader>cd", func = "definition_preview", desc = "Peek Definition" },
          { key = "<leader>cD", func = "definition", desc = "Go to Definition" },
          { key = "<leader>ct", func = "type_definition_preview", desc = "Peek Type Definition" },
          { key = "<leader>ch", func = "hover", desc = "Hover Documentation" },
          { key = "<leader>cf", func = "reference", desc = "Find References" },
          { key = "<leader>cn", func = "diagnostic_next", desc = "Next Diagnostic" },
          { key = "<leader>cp", func = "diagnostic_prev", desc = "Previous Diagnostic" },
          { key = "<leader>co", func = "symbols", desc = "Show Outline" },
          { key = "<leader>ci", func = "incoming_calls", desc = "Incoming Calls" },
          { key = "<leader>cu", func = "outgoing_calls", desc = "Outgoing Calls" },
        },
        default_mapping = false,
		    display_diagnostic_qf = "trouble",
      })
    end,
  },
}

return M
