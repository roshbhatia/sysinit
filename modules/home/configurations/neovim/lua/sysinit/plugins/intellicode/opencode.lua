local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

local function get_plugin_spec()
  local opencode_config = agents_config.agents.opencode
  if opencode_config.local_path then
    return {
      dir = vim.fn.expand(opencode_config.local_path),
      name = "opencode.nvim",
    }
  else
    return {
      "NickvanDyke/opencode.nvim",
    }
  end
end

M.plugins = {
  vim.tbl_deep_extend("force", get_plugin_spec(), {
    enabled = agents_config.agents.enabled and agents_config.agents.opencode.enabled,
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("opencode").setup({})

      vim.api.nvim_create_autocmd("User", {
        pattern = "OpencodeEvent",
        callback = function(args)
          if args.data and args.data.type == "session.idle" then
            vim.notify("opencode finished responding", vim.log.levels.INFO)
          end
        end,
      })
    end,
    keys = {
      {
        "<leader>ja",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask about cursor location",
        mode = "n",
      },
      {
        "<leader>ja",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask about selection",
        mode = "v",
      },
      {
        "<leader>jj",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle",
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
        "<leader>jy",
        function()
          require("opencode").command("messages_copy")
        end,
        desc = "Copy last message",
        mode = "n",
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("messages_half_page_up")
        end,
        desc = "Scroll messages up",
        mode = "n",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("messages_half_page_down")
        end,
        desc = "Scroll messages down",
        mode = "n",
      },
      {
        "<leader>jf",
        function()
          require("opencode").ask("Fix @diagnostics in this file: ")
        end,
        desc = "Fix all diagnostics in file",
        mode = "n",
      },
      {
        "<leader>jq",
        function()
          require("opencode").ask("@quickfix: ")
        end,
        desc = "Send quickfix list to opencode",
        mode = "n",
      },
      {
        "<leader>jp",
        function()
          require("opencode").select_prompt()
        end,
        desc = "Select prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>je",
        function()
          require("opencode").prompt("Explain @cursor and its context")
        end,
        desc = "Explain code near cursor",
        mode = "n",
      },
    },
  }),
}

return M
