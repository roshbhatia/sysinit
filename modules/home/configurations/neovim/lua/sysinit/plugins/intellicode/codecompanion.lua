local M = {}

local function get_env_bool(key, default)
  local value = vim.fn.getenv(key)
  if value == vim.NIL or value == "" then
    return default
  end
  return value:lower() == "true" or value == "1"
end

local function get_env_string(key, default)
  local value = vim.fn.getenv(key)
  if value == vim.NIL or value == "" then
    return default
  end
  return value
end

local agents = {
  enabled = get_env_bool("SYSINIT_NVIM_AGENTS_ENABLED", true),
  copilot = {
    enabled = get_env_bool("SYSINIT_NVIM_COPILOT_ENABLED", true),
  },
  claude_code = {
    enabled = get_env_bool("SYSINIT_NVIM_CODECOMPANION_CLAUDE_CODE_ENABLED", false),
  },
  preferred_adapter = get_env_string("SYSINIT_NVIM_CODECOMPANION_PREFERRED_ADAPTER", "auto"),
}

local function get_preferred_adapter()
  if agents.preferred_adapter ~= "auto" then
    return agents.preferred_adapter
  end

  if agents.claude_code.enabled then
    return "claude_code"
  end

  return "copilot"
end

M.plugins = {
  {
    "olimorris/codecompanion.nvim",
    enabled = agents.enabled,
    opts = {
      strategies = {
        chat = {
          adapter = get_preferred_adapter(),
        },
        inline = {
          adapter = get_preferred_adapter(),
        },
        cmd = {
          adapter = get_preferred_adapter(),
        },
      },
      adapters = {
        acp = {
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                CLAUDE_CODE_OAUTH_TOKEN = get_env_string("CLAUDE_CODE_OAUTH_TOKEN", ""),
              },
            })
          end,
        },
      },
      display = {
        action_palette = {
          provider = "telescope",
        },
        chat = {
          icons = {
            buffer_pin = " ",
            buffer_watch = " ",
          },
        },
        diff = {
          provider = "mini_diff",
        },
      },
      keymaps = {
        send = {
          modes = {
            n = { "<CR>", "<S-CR>" },
            i = "<S-CR>",
          },
          index = 2,
          callback = "keymaps.send",
          description = "Send",
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = function()
      return {
        {
          "<leader>kk",
          "<CMD>CodeCompanionChat Toggle<CR>",
          desc = "Toggle chat",
          mode = { "n", "v" },
        },
        {
          "<leader>kK",
          "<CMD>CodeCompanionChat<CR>",
          desc = "New chat",
          mode = { "n", "v" },
        },
        {
          "<leader>ke",
          "<CMD>CodeCompanion<CR>",
          desc = "Inline assistant",
          mode = { "n", "v" },
        },
        {
          "<leader>ka",
          "<CMD>CodeCompanionActions<CR>",
          desc = "Action palette",
          mode = { "n", "v" },
        },
        {
          "<leader>kc",
          "<CMD>CodeCompanionChat Add<CR>",
          desc = "Add current file to chat",
          mode = { "n", "v" },
        },
        {
          "<leader>k/",
          "<CMD>CodeCompanion /explain<CR>",
          desc = "Explain code",
          mode = "v",
        },
        {
          "<leader>k.",
          "<CMD>CodeCompanion /fix<CR>",
          desc = "Fix code",
          mode = "v",
        },
        {
          "<leader>k,",
          "<CMD>CodeCompanion /tests<CR>",
          desc = "Generate tests",
          mode = "v",
        },
        {
          "<leader>kl",
          "<CMD>CodeCompanion /lsp<CR>",
          desc = "Explain LSP diagnostics",
          mode = "v",
        },
        {
          "<leader>k:",
          "<CMD>CodeCompanionCmd<CR>",
          desc = "Generate command",
          mode = "n",
        },
      }
    end,
  },
}
return M
