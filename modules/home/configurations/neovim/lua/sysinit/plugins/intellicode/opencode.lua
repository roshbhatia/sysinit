local M = {}

M.plugins = {
  vim.tbl_deep_extend("force", get_plugin_spec(), {
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      vim.g.opencode_opts = {}
    end,
    keys = {
      {
        "<leader>ja",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask at cursor",
        mode = "n",
      },
      {
        "<leader>ja",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask at selection",
        mode = "v",
      },
      {
        "<leader>jj",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle agent ui",
        mode = "n",
      },
      {
        "<leader>jJ",
        function()
          require("opencode").command("session_new")
        end,
        desc = "New session",
        mode = "n",
      },
      {
        "<leader>jf",
        function()
          require("opencode").ask("Fix @diagnostics in this file: ")
        end,
        desc = "Fix diagnostics within file",
        mode = "n",
      },
      {
        "<leader>jq",
        function()
          require("opencode").ask("@quickfix: ")
        end,
        desc = "Ask with quickfix list",
        mode = "n",
      },
      {
        "<leader>jp",
        function()
          require("opencode").select_prompt()
        end,
        desc = "Ask with prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>je",
        function()
          require("opencode").prompt("Explain @cursor and its context")
        end,
        desc = "Explain at cursor",
        mode = "n",
      },
    },
  }),
}

return M
