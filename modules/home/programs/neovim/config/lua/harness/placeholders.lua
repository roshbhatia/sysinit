local M = {}

---@type table<string, fun(ctx: harness.EditorState): string|nil>
M.providers = {}

local context = require("harness.context")

local function safe_is_file(buf)
  if not buf then
    return false
  end
  local ok, result = pcall(function()
    return vim.api.nvim_buf_is_valid(buf) and context.is_file(buf)
  end)
  return ok and result == true
end

local function safe_buf_name(buf)
  if not buf then
    return nil
  end
  local ok, name = pcall(vim.api.nvim_buf_get_name, buf)
  if not ok or not name or name == "" then
    return nil
  end
  return name
end

local function safe_buf_get_lines(buf, start, end_)
  if not buf then
    return nil
  end
  local ok, lines = pcall(function()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return nil
    end
    return vim.api.nvim_buf_get_lines(buf, start, end_, false)
  end)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  return lines
end

M.providers.position = function(ctx)
  if not safe_is_file(ctx.buf) then
    return nil
  end
  local name = safe_buf_name(ctx.buf)
  if not name then
    return nil
  end
  local path = context.strip_git_root(name)
  return string.format("@%s:%d:%d", path, ctx.row, ctx.col)
end

M.providers.file = function(ctx)
  if not safe_is_file(ctx.buf) then
    return nil
  end
  local name = safe_buf_name(ctx.buf)
  if not name then
    return nil
  end
  return "@" .. context.strip_git_root(name)
end

M.providers.line = function(ctx)
  if not safe_is_file(ctx.buf) then
    return nil
  end
  local name = safe_buf_name(ctx.buf)
  if not name then
    return nil
  end
  local path = context.strip_git_root(name)
  return string.format("@%s:%d", path, ctx.row)
end

M.providers.cursor = M.providers.line
M.providers.buffer = M.providers.file

M.providers.buffers = function(_ctx)
  local items = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted and context.is_file(b) then
      local name = safe_buf_name(b)
      if name then
        table.insert(items, "- " .. context.strip_git_root(name))
      end
    end
  end
  return #items > 0 and table.concat(items, "\n") or nil
end

M.providers.selection = function(ctx)
  if not ctx.range then
    return nil
  end
  local lines = safe_buf_get_lines(ctx.buf, ctx.range.from[1] - 1, ctx.range.to[1])
  if not lines or #lines == 0 then
    return nil
  end
  if #lines == 1 then
    lines[1] = lines[1]:sub(ctx.range.from[2] + 1, ctx.range.to[2] + 1)
  else
    lines[1] = lines[1]:sub(ctx.range.from[2] + 1)
    lines[#lines] = lines[#lines]:sub(1, ctx.range.to[2] + 1)
  end
  local text = table.concat(lines, "\n")
  if text == "" then
    return nil
  end
  local name = safe_buf_name(ctx.buf)
  if not name then
    return nil
  end
  local path = context.strip_git_root(name)
  return string.format("@%s:%d-%d\n%s", path, ctx.range.from[1], ctx.range.to[1], text)
end

M.providers.word = function(ctx)
  local lines = safe_buf_get_lines(ctx.buf, ctx.row - 1, ctx.row)
  if not lines then
    return nil
  end
  local line = lines[1]
  if not line then
    return nil
  end
  local before = line:sub(1, ctx.col):match("[%w_]*$") or ""
  local after = line:sub(ctx.col + 1):match("^[%w_]*") or ""
  local word = before .. after
  return word ~= "" and word or nil
end

local severity_map = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN] = "WARN",
  [vim.diagnostic.severity.INFO] = "INFO",
  [vim.diagnostic.severity.HINT] = "HINT",
}

M.providers.diagnostic = function(ctx)
  if not ctx.row then
    return nil
  end
  local ok, diags = pcall(vim.diagnostic.get, ctx.buf, { lnum = ctx.row - 1 })
  if not ok or #diags == 0 then
    return nil
  end
  local lines = {}
  for _, d in ipairs(diags) do
    local sev = severity_map[d.severity] or "INFO"
    local msg = type(d.message) == "string" and d.message or tostring(d.message or "")
    table.insert(lines, string.format("[%s] %s", sev, msg))
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

M.providers.diagnostics = function(ctx)
  local ok, diags = pcall(vim.diagnostic.get, ctx.buf)
  if not ok or #diags == 0 then
    return nil
  end
  local lines = {}
  local max = 20
  for i, d in ipairs(diags) do
    if i > max then
      table.insert(lines, string.format("... and %d more", #diags - max))
      break
    end
    local sev = severity_map[d.severity] or "INFO"
    local msg = type(d.message) == "string" and d.message or tostring(d.message or "")
    table.insert(lines, string.format("Line %d: [%s] %s", d.lnum + 1, sev, msg))
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

---@param ctx harness.EditorState
local function ts_ancestor(ctx, type_patterns)
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    return nil
  end
  local parser_ok, _ = pcall(vim.treesitter.get_parser, ctx.buf)
  if not parser_ok then
    return nil
  end
  local get_ok, node = pcall(ts_utils.get_node_at_cursor)
  if not get_ok or not node then
    return nil
  end
  while node do
    local nt = node:type()
    for _, pat in ipairs(type_patterns) do
      if nt:match(pat) then
        local sr, _, er, _ = node:range()
        local lines = safe_buf_get_lines(ctx.buf, sr, er + 1)
        if lines and #lines > 0 then
          local name = safe_buf_name(ctx.buf)
          if not name then
            return nil
          end
          local path = context.strip_git_root(name)
          return string.format("@%s:%d-%d\n```\n%s\n```", path, sr + 1, er + 1, table.concat(lines, "\n"))
        end
        return nil
      end
    end
    node = node:parent()
  end
  return nil
end

M.providers["function"] = function(ctx)
  return ts_ancestor(ctx, { "function", "method", "definition" })
end

M.providers.class = function(ctx)
  return ts_ancestor(ctx, { "class", "struct", "interface", "module" })
end

local DIFF_MAX_BYTES = 32768

M.providers.git = function(_ctx)
  local result = vim.fn.system("git status --short --branch 2>/dev/null")
  if vim.v.shell_error ~= 0 or result == "" then
    return nil
  end
  return vim.trim(result)
end

M.providers.diff = function(ctx)
  if not safe_is_file(ctx.buf) then
    return nil
  end
  local path = safe_buf_name(ctx.buf)
  if not path then
    return nil
  end
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
  result = vim.trim(result)
  if #result > DIFF_MAX_BYTES then
    result = result:sub(1, DIFF_MAX_BYTES) .. "\n... (diff truncated)"
  end
  return result
end

M.providers.quickfix = function(_ctx)
  local qf = vim.fn.getqflist()
  if #qf == 0 then
    return nil
  end
  local lines = {}
  for _, e in ipairs(qf) do
    if e.valid == 1 then
      local fname = ""
      if e.bufnr and e.bufnr ~= 0 and vim.api.nvim_buf_is_valid(e.bufnr) then
        local ok, name = pcall(vim.api.nvim_buf_get_name, e.bufnr)
        if ok and name and name ~= "" then
          fname = vim.fn.fnamemodify(name, ":t")
        end
      end
      table.insert(lines, string.format("%s:%d: %s", fname, e.lnum, e.text or ""))
    end
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

M.providers.qflist = M.providers.quickfix

M.providers.loclist = function(ctx)
  local ll = vim.fn.getloclist(ctx.win)
  if #ll == 0 then
    return nil
  end
  local lines = {}
  for _, e in ipairs(ll) do
    if e.valid == 1 then
      local fname = ""
      if e.bufnr and e.bufnr ~= 0 and vim.api.nvim_buf_is_valid(e.bufnr) then
        local ok, name = pcall(vim.api.nvim_buf_get_name, e.bufnr)
        if ok and name and name ~= "" then
          fname = vim.fn.fnamemodify(name, ":t")
        end
      end
      table.insert(lines, string.format("%s:%d: %s", fname, e.lnum, e.text or ""))
    end
  end
  return #lines > 0 and table.concat(lines, "\n") or nil
end

M.providers.folder = function(ctx)
  if not safe_is_file(ctx.buf) then
    return nil
  end
  local name = safe_buf_name(ctx.buf)
  if not name then
    return nil
  end
  local dir = vim.fn.fnamemodify(name, ":h")
  return "@" .. context.strip_git_root(dir)
end

M.providers.marks = function(ctx)
  local ok, marks = pcall(vim.fn.getmarklist, ctx.buf)
  if not ok or not marks or #marks == 0 then
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

M.providers.search = function(_ctx)
  local ok, pat = pcall(vim.fn.getreg, "/")
  if not ok then
    return nil
  end
  return (pat and pat ~= "") and pat or nil
end

---@type {token: string, description: string}[]
M.descriptions = {
  { token = "+position", description = "Full location (file:line:col)" },
  { token = "+file", description = "Current file path" },
  { token = "+line", description = "File and line number" },
  { token = "+cursor", description = "Alias for +line" },
  { token = "+buffer", description = "Alias for +file" },
  { token = "+buffers", description = "List of open buffer paths" },
  { token = "+selection", description = "Visual selection text" },
  { token = "+word", description = "Word under cursor" },
  { token = "+diagnostic", description = "Diagnostics at current line" },
  { token = "+diagnostics", description = "All buffer diagnostics (max 20)" },
  { token = "+function", description = "Surrounding function (treesitter)" },
  { token = "+class", description = "Surrounding class (treesitter)" },
  { token = "+git", description = "Git status" },
  { token = "+diff", description = "Git diff for current file (max 32 KiB)" },
  { token = "+quickfix", description = "Quickfix list entries" },
  { token = "+qflist", description = "Alias for +quickfix" },
  { token = "+loclist", description = "Location list entries" },
  { token = "+folder", description = "Current folder path" },
  { token = "+marks", description = "Buffer marks" },
  { token = "+search", description = "Current search pattern" },
}

---@param parts  string[]
local function strip_token_whitespace(parts, pos, input, len)
  while pos <= len and input:sub(pos, pos) == " " do
    pos = pos + 1
  end
  while #parts > 0 and parts[#parts]:match("^%s*$") do
    table.remove(parts)
  end
  if #parts > 0 then
    parts[#parts] = parts[#parts]:gsub("%s+$", "")
  end
  local has_before = #parts > 0 and parts[#parts] ~= ""
  local has_after = pos <= len
  if has_before and has_after then
    table.insert(parts, " ")
  end
  return pos
end

---@param input  string
function M.apply(input, state)
  if not input or input == "" then
    return input
  end

  local ctx
  if state and state.ctx and state.cache then
    ctx = state
  else
    ctx = require("harness.context").new()
    if state and type(state) == "table" then
      for k, v in pairs(state) do
        ctx.ctx[k] = v
      end
    end
  end

  local parts = {}
  local pos = 1
  local len = #input

  while pos <= len do
    if input:sub(pos, pos) == "\\" and pos + 1 <= len and input:sub(pos + 1, pos + 1) == "+" then
      local token_match = input:match("^%+([%w_]+)", pos + 1)
      if token_match then
        table.insert(parts, "+" .. token_match)
        pos = pos + 1 + 1 + #token_match
      else
        table.insert(parts, "\\")
        pos = pos + 1
      end
    elseif input:sub(pos, pos) == "+" then
      local token_match = input:match("^%+([%w_]+)", pos)
      if token_match then
        local call_ok, value = pcall(ctx.get, ctx, token_match)
        if not call_ok then
          value = nil
        end
        if value then
          table.insert(parts, value)
        end
        if not value then
          pos = strip_token_whitespace(parts, pos + 1 + #token_match, input, len)
        else
          pos = pos + 1 + #token_match
        end
      else
        table.insert(parts, "+")
        pos = pos + 1
      end
    else
      local next_special = input:find("[\\+]", pos)
      if next_special then
        table.insert(parts, input:sub(pos, next_special - 1))
        pos = next_special
      else
        table.insert(parts, input:sub(pos))
        pos = len + 1
      end
    end
  end

  local result = table.concat(parts)
  result = result:match("^%s*(.-)%s*$")
  return result
end

return M
