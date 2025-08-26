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
        "<leader>jA",
        function()
          require("opencode").ask()
        end,
        desc = "Ask opencode",
        mode = "n",
      },
      {
        "<leader>ja",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask opencode about this",
        mode = "n",
      },
      {
        "<leader>ja",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask opencode about selection",
        mode = { "v", "\22" },
      },
      {
        "<leader>jj",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle embedded opencode",
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
          require("opencode").fix_diagnostics_in_file()
        end,
        desc = "Fix all diagnostics in file",
        mode = "n",
        mode = "n",
      },
      {
        "<leader>jq",
        function()
          require("opencode").send_qflist_to_opencode()
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

-- Fix all diagnostics in file via opencode
function M.fix_diagnostics_in_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local diags = vim.diagnostic.get(bufnr)
  if not diags or #diags == 0 then
    vim.notify("No diagnostics in this file", vim.log.levels.INFO)
    return
  end
  local lines = {}
  for _, d in ipairs(diags) do
    table.insert(lines, string.format("[%d] %s: %s", d.lnum + 1, d.source or "", d.message))
  end
  local prompt = "Fix all diagnostics in this file:\n" .. table.concat(lines, "\n")
  require("opencode").prompt(prompt)
end

-- Send quickfix list to opencode with a prompt
function M.send_qflist_to_opencode()
  local qflist = vim.fn.getqflist()
  if not qflist or #qflist == 0 then
    vim.notify("Quickfix list is empty", vim.log.levels.INFO)
    return
  end
  local lines = {}
  for _, item in ipairs(qflist) do
    local fname = item.bufnr and vim.api.nvim_buf_get_name(item.bufnr) or item.filename or ""
    table.insert(
      lines,
      string.format("%s:%d:%d: %s", fname, item.lnum or 0, item.col or 0, item.text or "")
    )
  end
  local prompt = "Review/fix these quickfix issues:\n" .. table.concat(lines, "\n")
  require("opencode").prompt(prompt)
end

return M
