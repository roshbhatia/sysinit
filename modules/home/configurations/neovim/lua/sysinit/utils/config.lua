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

local function get_config()
  return {
    debug = get_env_bool("SYSINIT_DEBUG", false),
    agents = {
      enabled = get_env_bool("SYSINIT_NVIM_AGENTS_ENABLED", true),
      avante = {
        enabled = get_env_bool("SYSINIT_NVIM_AVANTE_ENABLED", true),
        provider = get_env_string("SYSINIT_NVIM_AVANTE_PROVIDER", "goose"),
      },
      copilot = {
        enabled = get_env_bool("SYSINIT_NVIM_COPILOTLUA_ENABLED", true),
      },
      opencode = {
        enabled = get_env_bool("SYSINIT_NVIM_OPENCODE_ENABLED", true),
      },
      codecompanion = {
        enabled = get_env_bool("SYSINIT_NVIM_CODECOMPANION_ENABLED", true),
        adapter = get_env_string("SYSINIT_NVIM_CODECOMPANION_ADAPTER", "copilot"),
      },
    },
    external = {
      claude_code_token = get_env_string("CLAUDE_CODE_OAUTH_TOKEN", ""),
    },
  }
end

local _config = nil

function M.get()
  if not _config then
    _config = get_config()
  end
  return _config
end

function M.is_avante_enabled()
  return M.get().agents.enabled and M.get().agents.avante.enabled
end

function M.get_avante_provider()
  return M.get().agents.avante.provider
end

function M.is_agents_enabled()
  return M.get().agents.enabled
end

function M.is_copilot_enabled()
  return M.get().agents.enabled and M.get().agents.copilot.enabled
end

function M.is_opencode_enabled()
  return M.get().agents.enabled and M.get().agents.opencode.enabled
end

function M.is_codecompanion_enabled()
  return M.get().agents.enabled and M.get().agents.codecompanion.enabled
end

function M.get_codecompanion_adapter()
  return M.get().agents.codecompanion.adapter
end

function M.get_claude_code_token()
  return M.get().external.claude_code_token
end

return M
