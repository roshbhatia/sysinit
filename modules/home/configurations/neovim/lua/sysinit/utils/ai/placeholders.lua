local M = {}
local context = require("sysinit.utils.ai.context")

---@type table<string, fun(ctx: table): string|nil>
M.providers = {}

-- Position/Location providers

-- @this: Smart context (position for files, selection for non-files)
M.providers.this = function(ctx)
  if context.is_file(ctx.buf) then
    return M.providers.position(ctx)
  end
  return M.providers.selection(ctx)
end

-- @position: Full location (file:line:col)
M.providers.position = function(ctx)
  if not context.is_file(ctx.buf) then
    return nil
  end
  local path = context.strip_git_root(vim.api.nvim_buf_get_name(ctx.buf))
  return string.format("@%s:%d:%d", path, ctx.row, ctx.col)
end

-- @file: Current file path
M.providers.file = function(ctx)
  if not context.is_file(ctx.buf) then
    return nil
  end
  local path = context.strip_git_root(vim.api.nvim_buf_get_name(ctx.buf))
  return "@" .. path
end

-- @line: File and line number
M.providers.line = function(ctx)
  if not context.is_file(ctx.buf) then
    return nil
  end
  local path = context.strip_git_root(vim.api.nvim_buf_get_name(ctx.buf))
  return string.format("@%s:%d", path, ctx.row)
end

-- Aliases for compatibility
M.providers.cursor = M.providers.line
M.providers.buffer = M.providers.file

-- Buffer operations

-- @buffers: List all open buffer file paths
M.providers.buffers = function(ctx)
  local items = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted and context.is_file(b) then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        table.insert(items, "- " .. context.strip_git_root(name))
      end
    end
  end
  return #items > 0 and table.concat(items, "\n") or nil
end

-- @selection: Visual selection text
M.providers.selection = function(ctx)
  if not ctx.range then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(ctx.buf, ctx.range.from[1] - 1, ctx.range.to[1], false)
  if #lines == 0 then
    return nil
  end

  -- Trim to selection bounds
  if #lines == 1 then
    lines[1] = lines[1]:sub(ctx.range.from[2] + 1, ctx.range.to[2] + 1)
  else
    lines[1] = lines[1]:sub(ctx.range.from[2] + 1)
    lines[#lines] = lines[#lines]:sub(1, ctx.range.to[2] + 1)
  end

  local text = table.concat(lines, "\n")
  return text ~= "" and text or nil
end

-- @word: Word under cursor
M.providers.word = function(ctx)
  local line = vim.api.nvim_buf_get_lines(ctx.buf, ctx.row - 1, ctx.row, false)[1]
  if not line then
    return nil
  end
  local before = line:sub(1, ctx.col):match("[%w_]*$") or ""
  local after = line:sub(ctx.col + 1):match("^[%w_]*") or ""
  local word = before .. after
  return word ~= "" and word or nil
end

-- Diagnostics

-- @diagnostic: Diagnostics at current line only
M.providers.diagnostic = function(ctx)
  local diags = vim.diagnostic.get(ctx.buf, { lnum = ctx.row - 1 })
  if #diags == 0 then
    return nil
  end

  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }

  local lines = {}
  for _, d in ipairs(diags) do
    local sev = severity_map[d.severity] or "INFO"
    table.insert(lines, string.format("[%s] %s", sev, d.message))
  end
  return table.concat(lines, "\n")
end

-- @diagnostics: All buffer diagnostics (max 20)
M.providers.diagnostics = function(ctx)
  local diags = vim.diagnostic.get(ctx.buf)
  if #diags == 0 then
    return nil
  end

  local severity_map = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }

  local lines = {}
  local max_diags = 20
  for i, d in ipairs(diags) do
    if i > max_diags then
      table.insert(lines, string.format("... and %d more", #diags - max_diags))
      break
    end
    local sev = severity_map[d.severity] or "INFO"
    table.insert(lines, string.format("Line %d: [%s] %s", d.lnum + 1, sev, d.message))
  end
  return table.concat(lines, "\n")
end

-- Treesitter textobjects

-- @function: Surrounding function with code (treesitter)
M.providers["function"] = function(ctx)
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    return nil
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return nil
  end

  -- Walk up to find function node
  while node do
    local node_type = node:type()
    if node_type:match("function") or node_type:match("method") or node_type:match("definition") then
      local start_row, _, end_row, _ = node:range()
      local lines = vim.api.nvim_buf_get_lines(ctx.buf, start_row, end_row + 1, false)
      if #lines > 0 then
        local path = context.strip_git_root(vim.api.nvim_buf_get_name(ctx.buf))
        return string.format("@%s:%d-%d\n```\n%s\n```", path, start_row + 1, end_row + 1, table.concat(lines, "\n"))
      end
      return nil
    end
    node = node:parent()
  end

  return nil
end

-- @class: Surrounding class with code (treesitter)
M.providers.class = function(ctx)
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    return nil
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return nil
  end

  while node do
    local node_type = node:type()
    if
      node_type:match("class")
      or node_type:match("struct")
      or node_type:match("interface")
      or node_type:match("module")
    then
      local start_row, _, end_row, _ = node:range()
      local lines = vim.api.nvim_buf_get_lines(ctx.buf, start_row, end_row + 1, false)
      if #lines > 0 then
        local path = context.strip_git_root(vim.api.nvim_buf_get_name(ctx.buf))
        return string.format("@%s:%d-%d\n```\n%s\n```", path, start_row + 1, end_row + 1, table.concat(lines, "\n"))
      end
      return nil
    end
    node = node:parent()
  end

  return nil
end

-- Git operations

-- @git: Git status
M.providers.git = function(ctx)
  local result = vim.fn.system("git status --short --branch 2>/dev/null")
  if vim.v.shell_error ~= 0 or result == "" then
    return nil
  end
  return vim.trim(result)
end

-- @diff: Git diff for current file
M.providers.diff = function(ctx)
  if not context.is_file(ctx.buf) then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(ctx.buf)
  local root = context.get_git_root()
  if not root then
    return nil
  end

  local rel = context.strip_git_root(path)
  local result =
    vim.fn.system(string.format("git -C %s diff %s 2>/dev/null", vim.fn.shellescape(root), vim.fn.shellescape(rel)))
  if vim.v.shell_error ~= 0 or result == "" then
    return nil
  end
  return vim.trim(result)
end

-- Lists

-- @quickfix/@qflist: Quickfix list entries
M.providers.quickfix = function(ctx)
  local qf = vim.fn.getqflist()
  if #qf == 0 then
    return nil
  end

  local lines = {}
  for _, e in ipairs(qf) do
    if e.valid == 1 then
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(e.bufnr), ":t")
      local text = e.text or ""
      table.insert(lines, string.format("%s:%d: %s", fname, e.lnum, text))
    end
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

M.providers.qflist = M.providers.quickfix

-- @loclist: Location list entries
M.providers.loclist = function(ctx)
  local ll = vim.fn.getloclist(ctx.win)
  if #ll == 0 then
    return nil
  end

  local lines = {}
  for _, e in ipairs(ll) do
    if e.valid == 1 then
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(e.bufnr), ":t")
      local text = e.text or ""
      table.insert(lines, string.format("%s:%d: %s", fname, e.lnum, text))
    end
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

-- Misc

-- @folder: Current folder path
M.providers.folder = function(ctx)
  if not context.is_file(ctx.buf) then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(ctx.buf)
  local dir = vim.fn.fnamemodify(path, ":h")
  return "@" .. context.strip_git_root(dir)
end

-- @marks: Buffer marks
M.providers.marks = function(ctx)
  local marks = vim.fn.getmarklist(ctx.buf)
  if not marks or #marks == 0 then
    return nil
  end

  local result = {}
  for _, m in ipairs(marks) do
    if m.mark:match("^'[a-zA-Z]$") and m.pos[1] == ctx.buf then
      table.insert(result, string.format("'%s: line %d", m.mark:sub(2), m.pos[2]))
    end
  end
  return #result > 0 and table.concat(result, ", ") or nil
end

-- @search: Current search pattern
M.providers.search = function(ctx)
  local pattern = vim.fn.getreg("/")
  return (pattern and pattern ~= "") and pattern or nil
end

-- Description table for completion UI
M.descriptions = {
  { token = "@this", description = "Smart context (position for files, selection otherwise)" },
  { token = "@position", description = "Full location (file:line:col)" },
  { token = "@file", description = "Current file path" },
  { token = "@line", description = "File and line number" },
  { token = "@cursor", description = "Alias for @line" },
  { token = "@buffer", description = "Alias for @file" },
  { token = "@buffers", description = "List of open buffer paths" },
  { token = "@selection", description = "Visual selection text" },
  { token = "@word", description = "Word under cursor" },
  { token = "@diagnostic", description = "Diagnostics at current line" },
  { token = "@diagnostics", description = "All buffer diagnostics" },
  { token = "@function", description = "Surrounding function (treesitter)" },
  { token = "@class", description = "Surrounding class (treesitter)" },
  { token = "@git", description = "Git status" },
  { token = "@diff", description = "Git diff for current file" },
  { token = "@quickfix", description = "Quickfix list entries" },
  { token = "@qflist", description = "Alias for @quickfix" },
  { token = "@loclist", description = "Location list entries" },
  { token = "@folder", description = "Current folder path" },
  { token = "@marks", description = "Buffer marks" },
  { token = "@search", description = "Current search pattern" },
}

-- Escape Lua pattern special characters
local function escape_pattern(s)
  return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- Apply placeholders to input string
-- Handles @token format and supports fallbacks via context:get("a|b")
-- @param input string Input text with @tokens
-- @param state table|Context Optional state (raw table or Context object)
-- @return string Expanded text with placeholders substituted
function M.apply(input, state)
  if not input or input == "" then
    return input
  end

  -- Create context (uses provided state or captures fresh)
  local ctx
  if state and state.ctx and state.cache then
    -- Already a Context object
    ctx = state
  else
    ctx = context.new()
    -- If state was provided as raw table, override captured values
    if state and type(state) == "table" then
      for k, v in pairs(state) do
        ctx.ctx[k] = v
      end
    end
  end

  local result = input

  -- Find all @token patterns and replace
  -- Pattern: @word (letters, numbers, underscores)
  for token in input:gmatch("@([%w_]+)") do
    local value = ctx:get(token)
    if value then
      result = result:gsub("@" .. escape_pattern(token), value)
    end
  end

  return result
end

return M
