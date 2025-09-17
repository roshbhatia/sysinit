-- AI Terminals: Enhanced ai-terminals integration with unified AI services
local M = {}
local config = require("sysinit.utils.config")
local logger = require("sysinit.ai.core.logger")
local server = require("sysinit.ai.core.server")
local protocol = require("sysinit.ai.core.protocol")
local hooks = require("sysinit.ai.core.hooks")

-- Providers
local providers = {
  goose = require("sysinit.ai.providers.goose"),
  claude = require("sysinit.ai.providers.claude"),
  cursor = require("sysinit.ai.providers.cursor"),
  opencode = require("sysinit.ai.providers.opencode"),
}

-- Current sessions
local sessions = {}

-- Helper functions from original ai-terminals
local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

local function current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { buf = buf, bufnr = buf, file = file, line = line, col = col }
end

-- Compact diagnostic functions
local function get_compact_diagnostics(state)
  local diags = vim.diagnostic.get(state.buf) or {}
  if #diags == 0 then
    return ""
  end

  -- Use protocol's compact diagnostics
  return protocol._compact_diagnostics(diags)
end

local function get_buffer_content(state)
  if not vim.api.nvim_buf_is_loaded(state.buf) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if #text > 4000 then -- Reduced from 8000 for compactness
    text = text:sub(1, 4000) .. "\n...<truncated>"
  end
  return text
end

local function get_visual_selection()
  local save_reg = vim.fn.getreg('"')
  local save_regtype = vim.fn.getregtype('"')
  vim.cmd('normal! gv"gy')
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', save_reg, save_regtype)
  return selection or ""
end

-- Get quickfix list
local function get_quickfix_list()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return "No quickfix entries"
  end

  local entries = {}
  for i, entry in ipairs(qflist) do
    if i > 10 then -- Limit to 10 entries for compactness
      table.insert(entries, string.format("...and %d more entries", #qflist - 10))
      break
    end
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      if #text > 50 then
        text = text:sub(1, 47) .. "..."
      end
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "; ")
end

-- Get location list
local function get_location_list()
  local loclist = vim.fn.getloclist(0)
  if #loclist == 0 then
    return "No location list entries"
  end

  local entries = {}
  for i, entry in ipairs(loclist) do
    if i > 10 then -- Limit to 10 entries for compactness
      table.insert(entries, string.format("...and %d more entries", #loclist - 10))
      break
    end
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      if #text > 50 then
        text = text:sub(1, 47) .. "..."
      end
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "; ")
end

-- Enhanced placeholder system with compact data
local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Cursor position",
    provider = function(state)
      return string.format("%s:%d", state.file, state.line)
    end,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = function()
      return get_visual_selection()
    end,
  },
  {
    token = "@buffer",
    description = "Current buffer (compact)",
    provider = function(state)
      return get_buffer_content(state)
    end,
  },
  {
    token = "@diagnostics",
    description = "Compact diagnostics",
    provider = function(state)
      return get_compact_diagnostics(state)
    end,
  },
  {
    token = "@diff",
    description = "Git diff",
    provider = function(state)
      local filepath = vim.api.nvim_buf_get_name(state.bufnr)
      if filepath == "" then
        return "No file path available"
      end
      local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
      local output = vim.fn.system(cmd)
      return vim.v.shell_error ~= 0 and "No git diff available" or output
    end,
  },
  {
    token = "@qflist",
    description = "Quickfix list (compact)",
    provider = function()
      return get_quickfix_list()
    end,
  },
  {
    token = "@loclist",
    description = "Location list (compact)",
    provider = function()
      return get_location_list()
    end,
  },
}

local function apply_placeholders(input)
  if not input or input == "" then
    return input
  end
  local state = current_position()
  for _, ph in ipairs(PLACEHOLDERS) do
    if input:find(ph.token, 1, true) then
      local ok, value = pcall(ph.provider, state)
      if not ok then
        value = ""
      end
      value = value or ""
      input = input:gsub(escape_lua_pattern(ph.token), value)
    end
  end
  return input
end

-- Get context for AI
function M.get_context()
  local state = current_position()
  local context = {
    cursor = state,
    diagnostics = vim.diagnostic.get(state.buf),
    buffer = get_buffer_content(state),
  }

  -- Add git diff if available
  local diff_cmd = string.format("git diff %s", vim.fn.shellescape(state.file))
  local diff_output = vim.fn.system(diff_cmd)
  if vim.v.shell_error == 0 and diff_output ~= "" then
    context.diff = diff_output
  end

  return context
end

-- Send prompt to provider
function M.send_prompt(provider_name, text, opts)
  opts = opts or {}

  local provider = providers[provider_name]
  if not provider then
    vim.notify("Unknown provider: " .. provider_name, vim.log.levels.ERROR)
    return
  end

  -- Apply placeholders
  text = apply_placeholders(text)

  -- Get context
  local context = M.get_context()

  -- Ensure provider is set up
  if not sessions[provider_name] then
    sessions[provider_name] = logger.new(provider_name)
    provider.setup({
      logger = sessions[provider_name],
    })
    -- Start server if needed
    server.start(provider_name, {
      logger = sessions[provider_name],
    })
  end

  -- Log user message
  sessions[provider_name]:log_user_message(text)

  -- Send prompt
  provider.send_prompt(text, context)
end

-- Enhanced input creation with blink completion
local function create_input(provider, agent_icon, opts)
  opts = opts or {}
  local action_name = opts.action or "Ask"
  local prompt = opts.prompt or string.format("%s  %s", agent_icon, action_name)
  local title = string.format("%s  %s", agent_icon or "", action_name)

  local snacks = require("snacks")
  local snacks_opts = {
    prompt = prompt,
    title = title,
    icon = agent_icon,
    default = opts.default or "",
    win = {
      b = { completion = true },
      bo = { filetype = "ai_terminals_input" },
      relative = "cursor",
      style = "minimal",
      border = "rounded",
      width = math.max(40, math.min(80, vim.o.columns - 20)),
      height = 1,
      row = 1,
      col = 0,
    },
  }

  snacks.input(snacks_opts, function(value)
    if opts.on_confirm and value and value ~= "" then
      opts.on_confirm(value)
    end
  end)
end

-- Create keymaps for provider
local function create_keymaps(agent)
  local key_prefix, provider_name, label, icon = agent[1], agent[2], agent[3], agent[4]
  return {
    {
      string.format("<leader>%s%s", key_prefix, key_prefix),
      function()
        local ai_terminals = require("ai-terminals")
        ai_terminals.toggle(provider_name)
      end,
      desc = "Toggle " .. provider_name .. " terminal",
    },
    {
      string.format("<leader>%sa", key_prefix),
      function()
        local mode = vim.fn.mode()
        local default_text = mode:match("[vV]") and " @selection: " or " @cursor: "

        create_input(provider_name, icon, {
          action = "Ask",
          default = default_text,
          on_confirm = function(text)
            M.send_prompt(provider_name, text)
          end,
        })
      end,
      desc = "Ask " .. label,
    },
    {
      string.format("<leader>%sf", key_prefix),
      function()
        create_input(provider_name, icon, {
          action = "Fix diagnostics",
          default = " Fix @diagnostics: ",
          on_confirm = function(text)
            M.send_prompt(provider_name, text)
          end,
        })
      end,
      desc = "Fix diagnostics with " .. label,
    },
    {
      string.format("<leader>%sc", key_prefix),
      function()
        local mode = vim.fn.mode()
        local default_text = mode:match("[vV]") and " Comment @selection: " or " Comment @cursor: "

        create_input(provider_name, icon, {
          action = "Comment",
          default = default_text,
          on_confirm = function(text)
            M.send_prompt(provider_name, text)
          end,
        })
      end,
      desc = "Comment with " .. label,
    },
  }
end

-- Setup blink completion for placeholders
local blink_source = {}
local blink_source_setup_done = false

function blink_source.setup()
  if blink_source_setup_done then
    return
  end
  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return
  end
  blink.add_source_provider(
    "ai_placeholders",
    { module = "sysinit.ai.terminals", name = "ai_placeholders" }
  )
  blink.add_filetype_source("ai_terminals_input", "ai_placeholders")
  blink_source_setup_done = true
end

function blink_source.new(opts)
  local self = setmetatable({}, { __index = blink_source })
  self.opts = opts or {}
  return self
end

function blink_source:enabled()
  return vim.bo.filetype == "ai_terminals_input"
end

function blink_source:get_trigger_characters()
  return { "@" }
end

function blink_source:get_completions(_, callback)
  local items = {}
  local types_ok, types = pcall(require, "blink.cmp.types")
  if not types_ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end

  for _, p in ipairs(PLACEHOLDERS) do
    table.insert(items, {
      label = p.token,
      kind = types.CompletionItemKind.Enum,
      filterText = p.token,
      insertText = p.token,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      documentation = {
        kind = "markdown",
        value = string.format("`%s`\n\n%s", p.token, p.description),
      },
    })
  end

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  return function() end
end

function blink_source:resolve(item, callback)
  callback(item)
end

-- Export blink source
M.new = function(opts)
  return blink_source.new(opts)
end
M.setup_blink_source = blink_source.setup

-- Main plugin configuration
M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      -- Setup hooks integration
      hooks.setup({
        hooks = {
          [hooks.EVENTS.SESSION_START] = {
            {
              hooks = {
                {
                  type = "command",
                  command = "echo 'AI session started with enhanced logging'",
                },
              },
            },
          },
        },
      })

      -- Setup blink completion
      M.setup_blink_source()

      -- Configure ai-terminals with our providers
      require("ai-terminals").setup({
        window_dimensions = {
          right = {
            width = 0.4,
            height = 1.0,
          },
        },
        default_position = "right",
        trigger_formatting = {
          enabled = true,
        },
        watch_cwd = {
          enabled = true,
          ignore = {
            "**/.git/**",
            "**/node_modules/**",
            "**/.venv/**",
            "**/*.log",
            "**/bin/**",
            "**/dist/**",
            "**/vendor/**",
            "**/.local/share/goose/**", -- Ignore goose logs
          },
          gitignore = true,
        },
        env = {
          PAGER = "bat",
          GOOSE_LOG_LEVEL = "INFO",
        },
      })
    end,
    keys = function()
      local agents = {
        { "h", "goose", "Goose", "🪿" },
        { "y", "claude", "Claude", "󰿟󰫮" },
        { "u", "cursor", "Cursor", "" },
        { "o", "opencode", "OpenCode", "⚡" },
      }

      local mappings = {}
      for _, agent in ipairs(agents) do
        vim.list_extend(mappings, create_keymaps(agent))
      end

      return mappings
    end,
  },
}

return M
