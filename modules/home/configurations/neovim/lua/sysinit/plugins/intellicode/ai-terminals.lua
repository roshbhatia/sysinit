-- Module for AI terminals integration with Neovim
local M = {}
local config = require("sysinit.utils.config")

-- Utility Functions
-- Escapes Lua pattern special characters for safe pattern matching
local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

-- Sends an LSP request and returns the result with a default timeout
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

-- Gets current cursor position and buffer details
local function current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { buf = buf, file = file, line = line, col = col }
end

-- Diagnostic Functions
-- Gets diagnostics for the current line
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

-- Gets all diagnostics for the buffer
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

-- Buffer and File Functions
-- Returns the buffer's file path prefixed with '@'
local function get_buffer_path(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end
  local path = vim.api.nvim_buf_get_name(state.buf)
  return path ~= "" and "@" .. path or ""
end

-- Summarizes all loaded and listed buffers
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

-- Selection and Content Functions
-- Retrieves the current visual selection
local function get_visual_selection()
  local save_reg = vim.fn.getreg('"')
  local save_regtype = vim.fn.getregtype('"')
  vim.cmd('normal! gv"gy')
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', save_reg, save_regtype)
  return selection or ""
end

-- Gets the visible content in the current window
local function get_visible_content(state)
  local win = vim.api.nvim_get_current_win()
  local top_line = vim.fn.line("w0")
  local bottom_line = vim.fn.line("w$")
  local bufnr = state.buf
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bottom_line, false)
  return table.concat(lines, "\n")
end

-- LSP Functions
-- Retrieves LSP hover documentation at the cursor
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

-- Retrieves available LSP code actions
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

-- Quickfix and Location List Functions
-- Retrieves the quickfix list
local function get_quickfix_list()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return "No quickfix entries"
  end
  local entries = {}
  for _, entry in ipairs(qflist) do
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "\n")
end

-- Retrieves the location list
local function get_location_list()
  local loclist = vim.fn.getloclist(0)
  if #loclist == 0 then
    return "No location list entries"
  end
  local entries = {}
  for _, entry in ipairs(loclist) do
    if entry.valid == 1 then
      local bufname = vim.api.nvim_buf_get_name(entry.bufnr)
      local filename = vim.fn.fnamemodify(bufname, ":t")
      local text = entry.text or ""
      table.insert(entries, string.format("%s:%d: %s", filename, entry.lnum, text))
    end
  end
  return table.concat(entries, "\n")
end

-- Git Diff and Native Diff Functions
-- Retrieves the git diff for the current buffer
local function get_git_diff(state)
  local bufnr = state.buf
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)
  if output == "" then
    vim.notify("No git diff available for " .. filepath, vim.log.levels.WARN)
    return "No git diff available"
  end
  return output
end

-- Populates quickfix list with diff changes
local function populate_qflist_with_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff --no-color %s", vim.fn.shellescape(filepath))
  local output = vim.fn.systemlist(cmd)
  if output == nil or #output == 0 then
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end

  local qf_entries = {}
  local current_file = filepath
  local lnum = 0
  for _, line in ipairs(output) do
    -- Parse diff headers for line numbers
    if line:match("^@@") then
      local new_lnum = line:match("^@@ %-%d+,%d+ %+(%d+),")
      if new_lnum then
        lnum = tonumber(new_lnum) - 1
      end
    elseif line:match("^%+") and not line:match("^%+%+%+") then
      lnum = lnum + 1
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = line:sub(2), -- Remove '+' prefix
        type = "I", -- Info type for added lines
      })
    elseif line:match("^%-") and not line:match("^%-%-%-") then
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = "Removed: " .. line:sub(2), -- Remove '-' prefix
        type = "W", -- Warning type for removed lines
      })
    end
  end

  if #qf_entries > 0 then
    vim.fn.setqflist(qf_entries, "r")
    return "Quickfix list populated with diff changes"
  else
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end
end

-- Opens a native diff view in a vertical split
local function open_native_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end

  -- Create a temporary file with the git HEAD version
  local temp_file = vim.fn.tempname()
  local cmd = string.format(
    "git show HEAD:%s > %s",
    vim.fn.shellescape(filepath),
    vim.fn.shellescape(temp_file)
  )
  local result = vim.fn.system(cmd)
  if result ~= "" then
    vim.notify("Failed to retrieve git HEAD version for " .. filepath, vim.log.levels.WARN)
    vim.fn.delete(temp_file)
    return "Failed to retrieve git HEAD version"
  end

  -- Open a vertical split with the temporary file
  vim.cmd("vsplit " .. temp_file)
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(new_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe")
  vim.cmd("diffthis")
  vim.cmd("wincmd p")
  vim.cmd("diffthis")

  -- Clean up the temporary file when the buffer is closed
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = new_buf,
    callback = function()
      vim.fn.delete(temp_file)
    end,
    once = true,
  })

  return "Native diff view opened"
end

-- Opens diff view using diffview.nvim if available, else falls back to native diff
local function open_diff_view(state)
  local has_diffview, _ = pcall(require, "diffview")
  if has_diffview then
    local filepath = vim.api.nvim_buf_get_name(state.buf)
    if filepath == "" then
      return "No file path available"
    end
    vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(filepath))
    return "Diffview opened"
  else
    return open_native_diff(state)
  end
end

-- Placeholder Definitions
local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      return string.format("%s:%d", get_buffer_path(state), state.line)
    end,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = get_visual_selection,
  },
  {
    token = "@buffer",
    description = "Current buffer's file path",
    provider = get_buffer_path,
  },
  {
    token = "@buffers",
    description = "List of open buffers",
    provider = get_all_buffers_summary,
  },
  {
    token = "@visible",
    description = "Visible text in the current window",
    provider = get_visible_content,
  },
  {
    token = "@diagnostic",
    description = "Diagnostics for the current line",
    provider = get_line_diagnostics,
  },
  {
    token = "@diagnostics",
    description = "All diagnostics in the current buffer",
    provider = get_all_diagnostics,
  },
  {
    token = "@qflist",
    description = "Quickfix list entries",
    provider = get_quickfix_list,
  },
  {
    token = "@loclist",
    description = "Location list entries",
    provider = get_location_list,
  },
  {
    token = "@diff",
    description = "Git diff for the current buffer",
    provider = get_git_diff,
  },
  {
    token = "@docs",
    description = "LSP hover documentation at cursor",
    provider = get_hover_docs,
  },
  {
    token = "@codeactions",
    description = "Available LSP code action titles",
    provider = get_code_actions,
  },
}

-- Placeholder Application
-- Applies placeholders to the input string
local function apply_placeholders(input)
  if not input or input == "" then
    return input
  end
  local state = current_position()
  local result = input
  for _, ph in ipairs(PLACEHOLDERS) do
    if result:find(ph.token, 1, true) then
      local ok, value = pcall(ph.provider, state)
      value = ok and value or ""
      result = result:gsub(escape_lua_pattern(ph.token), value)
    end
  end
  return result
end

M.placeholder_descriptions = vim.tbl_map(function(p)
  return { token = p.token, description = p.description }
end, PLACEHOLDERS)

-- Blink Completion Source
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
  return setmetatable({}, { __index = blink_source }):init(opts or {})
end

function blink_source:init(opts)
  self.opts = opts
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

M.new = blink_source.new
M.setup_blink_source = blink_source.setup

-- Plugin Configuration
M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = { "folke/snacks.nvim" },
    config = function()
      M.setup_blink_source()
      require("ai-terminals").setup({
        window_dimensions = {
          right = {
            width = 0.4,
            height = 1.0,
          },
        },
        backend = "snacks",
        default_position = "right",
        trigger_formatting = {
          enabled = true,
          notify = false,
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

      -- Creates a floating input window for sending commands to a terminal
      local function create_input(termname, agent_icon, opts)
        opts = opts or {}
        local action_name = opts.action or "Ask"
        local prompt = string.format("%s  %s", agent_icon, action_name)
        local title = string.format("%s  %s", agent_icon or "", action_name)

        snacks.input({
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
        }, function(value)
          if opts.on_confirm and value and value ~= "" then
            opts.on_confirm(apply_placeholders(value))
          end
        end)
      end

      -- Generates keymaps for a given AI agent
      local function create_keymaps(agent)
        local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]
        return {
          -- Toggle terminal
          {
            string.format("<leader>%s%s", key_prefix, key_prefix),
            function()
              ai_terminals.toggle(termname)
            end,
            desc = "Toggle " .. label,
          },
          -- Ask with cursor or selection
          {
            string.format("<leader>%sa", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " @selection: " or " @cursor: "
              create_input(termname, icon, {
                action = "Ask",
                default = default_text,
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Ask " .. label,
          },
          -- Fix diagnostics
          {
            string.format("<leader>%sf", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Fix diagnostics",
                default = " Fix @diagnostic: ",
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            desc = "Fix diagnostics with " .. label,
          },
          -- Comment code
          {
            string.format("<leader>%sc", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " Comment @selection: "
                or " Comment @cursor: "
              create_input(termname, icon, {
                action = "Comment",
                default = default_text,
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Comment with " .. label,
          },
          -- Send quickfix list
          {
            string.format("<leader>%sq", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Analyze quickfix list",
                default = " Analyze @qflist: ",
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            desc = "Send quickfix list to " .. label,
          },
          -- Send location list
          {
            string.format("<leader>%sl", key_prefix),
            function()
              create_input(termname, icon, {
                action = "Analyze location list",
                default = " Analyze @loclist: ",
                on_confirm = function(text)
                  ai_terminals.send_term(termname, text, { submit = true })
                end,
              })
            end,
            desc = "Send location list to " .. label,
          },
          -- View diff (diffview.nvim or native)
          {
            string.format("<leader>%sd", key_prefix),
            function()
              local state = current_position()
              local result = open_diff_view(state)
              if result ~= "Diffview opened" and result ~= "Native diff view opened" then
                vim.notify(result, vim.log.levels.WARN)
              end
            end,
            desc = "View diff with " .. label,
          },
          -- Populate quickfix with diff
          {
            string.format("<leader>%sp", key_prefix),
            function()
              local state = current_position()
              local result = populate_qflist_with_diff(state)
              if result ~= "Quickfix list populated with diff changes" then
                vim.notify(result, vim.log.levels.WARN)
              else
                vim.notify(result, vim.log.levels.INFO)
              end
            end,
            desc = "Populate quickfix with diff for " .. label,
          },
        }
      end

      local agents = {
        { "h", "goose", "Goose", "" },
        { "y", "claude", "Claude", "󰿟󰫮" },
        { "u", "cursor", "Cursor", "" },
        { "j", "opencode", "OpenCode", "󰫼󰫰" },
      }

      return vim.iter(agents):fold({}, function(acc, agent)
        return vim.list_extend(acc, create_keymaps(agent))
      end)
    end,
  },
}

return M
