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
          code_action_icon = '󰘧',
          diagnostic_head = '"',
          diagnostic_head_severity_1 = '󱢇'
        },
        default_mapping = false,
        display_diagnostic_qf = "trouble",
      })
    end,
    keys = function()
      return {
        { "<leader>ca", function() require("navigator.codeAction").code_action() end, desc = "Code Action" },
        { "<leader>cr", function() require("navigator.rename").rename() end, desc = "Rename" },
        { "<leader>cd", function() require("navigator.definition").definition_preview() end, desc = "Peek Definition" },
        { "<leader>cD", function() require("navigator.definition").definition() end, desc = "Go to Definition" },
        { "<leader>ct", function() require("navigator.definition").type_definition_preview() end, desc = "Peek Type Definition" },
        { "<leader>cf", function() require("navigator.reference").reference() end, desc = "Find References" },
        { "<leader>cn", function() require("navigator.diagnostics").goto_next() end, desc = "Next Diagnostic" },
        { "<leader>cp", function() require("navigator.diagnostics").goto_prev() end, desc = "Previous Diagnostic" },
        { "<leader>co", function() require("navigator.symbols").document_symbols() end, desc = "Show Outline" },
        { "<leader>ci", function() require("navigator.hierarchy").incoming_calls() end, desc = "Incoming Calls" },
        { "<leader>cu", function() require("navigator.hierarchy").outgoing_calls() end, desc = "Outgoing Calls" },
      }
    end,
  },
