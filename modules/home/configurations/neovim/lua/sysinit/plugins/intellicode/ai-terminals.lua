local M = {}
local config = require("sysinit.utils.config")

local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

local function lsp_request(method, params, timeout)
  local ok, result = pcall(vim.lsp.buf_request_sync, 0, method, params, timeout or 500)
  if not ok or not result then
    return nil
  end
  for _, res in pairs(result) do
    if res.result then
      return res.result
    end
  end
  return nil
end

local function current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { buf = buf, file = file, line = line, col = col }
end

local function get_line_diagnostics(state)
  local diags = vim.diagnostic.get(state.buf, { lnum = state.line - 1 }) or {}
  if #diags == 0 then
    return ""
  end
  return table.concat(
    vim.tbl_map(function(d)
      return string.format("Line %d: %s", d.lnum + 1, d.message)
    end, diags),
    "; "
  )
end

local function get_all_diagnostics(state)
  local diags = vim.diagnostic.get(state.buf) or {}
  if #diags == 0 then
    return ""
  end
  local grouped = {}
  for _, d in ipairs(diags) do
    local severity = vim.diagnostic.severity[d.severity] or "INFO"
    table.insert(grouped, string.format("[%s] Line %d: %s", severity, d.lnum + 1, d.message))
  end
  return table.concat(grouped, "\n")
end

local function get_buffer_content(state)
  if not vim.api.nvim_buf_is_loaded(state.buf) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if #text > 8000 then
    text = text:sub(1, 8000) .. "\n...<truncated>"
  end
  return text
end

local function get_all_buffers_summary()
  local bufs = vim.api.nvim_list_bufs()
  local items = {}
  for _, b in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_option(b, "buflisted") then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        table.insert(items, name)
      end
    end
  end
  return table.concat(items, "\n")
end

local function get_hover_docs(state)
  local params = vim.lsp.util.make_position_params()
  local result = lsp_request("textDocument/hover", params)
  if not result then
    return ""
  end
  local contents = result.contents
  local out = {}
  if type(contents) == "string" then
    table.insert(out, contents)
  elseif vim.tbl_islist(contents) then
    for _, c in ipairs(contents) do
      if type(c) == "string" then
        table.insert(out, c)
      elseif type(c) == "table" and c.value then
        table.insert(out, c.value)
      end
    end
  elseif type(contents) == "table" and contents.value then
    table.insert(out, contents.value)
  end
  return table.concat(out, "\n")
end

local function get_code_actions(state)
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.diagnostic.get(state.buf) }
  local result = lsp_request("textDocument/codeAction", params)
  if not result or #result == 0 then
    return ""
  end
  local titles = {}
  for _, action in ipairs(result) do
    if action.title then
      table.insert(titles, action.title)
    end
  end
  return table.concat(titles, "; ")
end

---@class PlaceholderDef
---@field token string
---@field description string
---@field provider fun(state: table): string
local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Current file path with line number",
    provider = function(state)
      return string.format("%s:%d", state.file, state.line)
    end,
  },
  {
    token = "@diagnostics",
    description = "Diagnostics messages on current line with line numbers",
    provider = function(state)
      return get_line_diagnostics(state)
    end,
  },
  {
    token = "@alldiagnostics",
    description = "All diagnostics in current buffer with severity and line numbers",
    provider = function(state)
      return get_all_diagnostics(state)
    end,
  },
  {
    token = "@buffer",
    description = "Entire current buffer (truncated to 8k chars)",
    provider = function(state)
      return get_buffer_content(state)
    end,
  },
  {
    token = "@buffers",
    description = "List of loaded buffers (paths)",
    provider = function()
      return get_all_buffers_summary()
    end,
  },
  {
    token = "@docs",
    description = "LSP hover documentation at cursor",
    provider = function(state)
      return get_hover_docs(state)
    end,
  },
  {
    token = "@codeactions",
    description = "Available LSP code action titles",
    provider = function(state)
      return get_code_actions(state)
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

M.placeholder_descriptions = vim.tbl_map(function(p)
  return { token = p.token, description = p.description }
end, PLACEHOLDERS)

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
    { module = "sysinit.plugins.intellicode.ai-terminals", name = "ai_placeholders" }
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
  for _, p in ipairs(M.placeholder_descriptions) do
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

M.new = function(opts)
  return blink_source.new(opts)
end
M.setup_blink_source = blink_source.setup

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      M.setup_blink_source()
      require("ai-terminals").setup({
        window_dimensions = {
          right = {
            width = 0.4,
            height = 1.0,
          },
        },
        default_position = "right",
        enable_diffing = true,
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
          },
          gitignore = true,
        },
        env = {
          PAGER = "bat",
        },
      })
    end,
    keys = function()
      local ai_terminals = require("ai-terminals")
      local snacks = require("snacks")

      local function create_input(termname, agent_icon, opts)
        opts = opts or {}
        local prompt = opts.prompt or "Input:"
        local title = string.format("%s %s", agent_icon or "", termname)
        local win_opts = {
          b = { completion = true },
          bo = { filetype = "ai_terminals_input" },
        }
        local snacks_opts = {
          prompt = prompt,
          title = title,
          default = opts.default or "",
          win = win_opts,
        }
        snacks.input(snacks_opts, function(value)
          local cb = opts.on_confirm or opts.on_submit
          if cb and value and value ~= "" then
            cb(apply_placeholders(value))
          end
        end)
      end

      local function create_keymaps(agent)
        local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]
        return {
          {
            string.format("<leader>%sh", key_prefix),
            function()
              ai_terminals.toggle(termname)
            end,
            desc = icon .. " " .. label .. ": Toggle terminal",
          },
          {
            string.format("<leader>%sa", key_prefix),
            function()
              create_input(termname, icon, {
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            desc = icon .. " " .. label .. ": Ask (supports placeholders)",
          },
          {
            string.format("<leader>%sf", key_prefix),
            function()
              ai_terminals.send_diagnostics(termname, { submit = true })
            end,
            desc = icon .. " " .. label .. ": Fix diagnostics",
          },
          {
            string.format("<leader>%sc", key_prefix),
            function()
              ai_terminals.comment(termname)
            end,
            desc = icon .. " " .. label .. ": Comment",
          },
        }
      end

      local agents = {
        { "h", "goose", "Goose", "" },
        { "y", "claude", "Claude", "󰿟󰫮" },
        { "u", "cursor", "Cursor", "" },
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
