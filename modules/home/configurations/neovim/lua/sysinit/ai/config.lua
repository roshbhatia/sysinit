-- AI Configuration: Setup and configuration for the unified AI system
local M = {}

-- Default configuration
M.defaults = {
  -- Provider-specific settings
  providers = {
    goose = {
      port = 9100,
      enabled = true,
      auto_start = true,
    },
    claude = {
      port = 9101,
      enabled = true,
      auto_start = false, -- Claude Code manages its own lifecycle
    },
    cursor = {
      port = 9102,
      enabled = true,
      auto_start = true,
    },
    opencode = {
      port = 9103,
      enabled = true,
      auto_start = true,
    },
  },

  -- Logging configuration
  logging = {
    enabled = true,
    use_goose_format = true,
    session_retention_days = 30,
  },

  -- File watching
  file_watching = {
    enabled = true,
    auto_reload_clean_buffers = true,
    show_diff_for_modified = true,
  },

  -- Claude Code hooks integration
  hooks = {
    enabled = true,
    load_from_settings = true,
    custom_hooks = {
      -- Example: Log all AI interactions
      ["UserPromptSubmit"] = {
        {
          hooks = {
            {
              type = "command",
              command = "echo 'AI prompt submitted' >> ~/.local/share/goose/ai-activity.log",
            },
          },
        },
      },
      -- Example: Notify on file changes
      ["PostToolUse"] = {
        {
          matcher = "Write|Edit",
          hooks = {
            {
              type = "command",
              command = "echo 'File modified by AI: $(date)' >> ~/.local/share/goose/file-changes.log",
            },
          },
        },
      },
    },
  },

  -- AI Terminals configuration
  terminals = {
    enabled = true,
    compact_diagnostics = true,
    max_context_size = 4000, -- Reduced for faster processing
    placeholders = {
      "@cursor",
      "@selection",
      "@buffer",
      "@diagnostics",
      "@diff",
      "@qflist",
      "@loclist",
      "@vectorcode",
    },
  },
}

-- Merge user config with defaults
function M.setup(user_config)
  user_config = user_config or {}
  return vim.tbl_deep_extend("force", M.defaults, user_config)
end

-- Get agent configuration
function M.get_agents()
  return {
    { "h", "goose", "Goose", "" },
    { "y", "claude", "Claude", "󰿟󰫮" },
    { "u", "cursor", "Cursor", "" },
    { "j", "opencode", "OpenCode", "󰫼󰫰" },
  }
end

-- Get keybinding configuration
function M.get_keybindings(config)
  config = config or M.defaults

  local keybindings = {
    ["<leader>ai"] = "AI: Show status",
    ["<leader>aI"] = "AI: Setup all services",
    ["<leader>ac"] = "AI: Cleanup old sessions",
    ["<leader>al"] = "AI: Show logs",
  }

  -- Add agent-specific keybindings
  for _, agent in ipairs(M.get_agents()) do
    local key_prefix, provider, label = agent[1], agent[2], agent[3]

    if config.providers[provider] and config.providers[provider].enabled then
      keybindings[string.format("<leader>%s%s", key_prefix, key_prefix)] = "Toggle "
        .. label
        .. " terminal"
      keybindings[string.format("<leader>%sa", key_prefix)] = "Ask " .. label
      keybindings[string.format("<leader>%sf", key_prefix)] = "Fix diagnostics with " .. label
      keybindings[string.format("<leader>%sc", key_prefix)] = "Comment with " .. label
    end
  end

  return keybindings
end

-- Validate configuration
function M.validate(config)
  local errors = {}

  -- Check provider ports
  local used_ports = {}
  for name, provider_config in pairs(config.providers) do
    if provider_config.enabled then
      local port = provider_config.port
      if used_ports[port] then
        table.insert(
          errors,
          string.format(
            "Port %d is used by multiple providers: %s and %s",
            port,
            used_ports[port],
            name
          )
        )
      else
        used_ports[port] = name
      end
    end
  end

  -- Check for required dependencies
  local required_plugins = {
    "folke/snacks.nvim",
    "aweis89/ai-terminals.nvim",
  }

  for _, plugin in ipairs(required_plugins) do
    if not pcall(require, plugin:match("/(.+)$"):gsub("%.nvim$", "")) then
      table.insert(errors, "Missing required plugin: " .. plugin)
    end
  end

  return #errors == 0, errors
end

return M
