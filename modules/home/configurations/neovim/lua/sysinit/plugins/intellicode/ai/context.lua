local M = {}
local lsp = require("sysinit.plugins.intellicode.ai.lsp")

function M.current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if repo_root and repo_root ~= "" then
    file = file:sub(#repo_root + 2)
  end

  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { buf = buf, file = file, line = line, col = col }
end

function M.get_line_diagnostics(state)
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

function M.get_all_diagnostics(state)
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

function M.get_buffer_path(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local path = vim.api.nvim_buf_get_name(state.buf)
  if path == "" then
    return ""
  end

  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if repo_root and repo_root ~= "" then
    path = path:sub(#repo_root + 2)
  end

  return "@" .. path
end

function M.get_all_buffers_summary()
  local handle = io.popen("git rev-parse --show-toplevel")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  local bufs = vim.api.nvim_list_bufs()
  local items = {}
  for _, b in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_option(b, "buflisted") then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        if repo_root and repo_root ~= "" and name:sub(1, #repo_root) == repo_root then
          name = name:sub(#repo_root + 2)
        end
        table.insert(items, name)
      end
    end
  end
  return table.concat(items, "\n")
end

function M.get_visual_selection()
  local save_reg = vim.fn.getreg('"')
  local save_regtype = vim.fn.getregtype('"')
  vim.cmd('normal! gv"gy')
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', save_reg, save_regtype)
  return selection or ""
end

function M.get_visible_content(state)
  local win = vim.api.nvim_get_current_win()
  local top_line = vim.fn.line("w0")
  local bottom_line = vim.fn.line("w$")
  local bufnr = state.buf
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bottom_line, false)
  return table.concat(lines, "\n")
end

function M.get_hover_docs(state)
  local params = vim.lsp.util.make_position_params()
  local result = lsp.request("textDocument/hover", params)
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

function M.get_code_actions(state)
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.diagnostic.get(state.buf) }
  local result = lsp.request("textDocument/codeAction", params)
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

function M.get_quickfix_list()
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

function M.get_location_list()
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

function M.get_filetype(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end
  return vim.api.nvim_buf_get_option(state.buf, "filetype")
end

function M.get_surrounding_lines(state, before, after)
  before = before or 5
  after = after or 5

  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local start_line = math.max(0, state.line - 1 - before)
  local end_line = math.min(vim.api.nvim_buf_line_count(state.buf), state.line + after)

  local lines = vim.api.nvim_buf_get_lines(state.buf, start_line, end_line, false)

  local result = {}
  for i, line in ipairs(lines) do
    local line_num = start_line + i
    local marker = (line_num == state.line) and ">>> " or "    "
    table.insert(result, string.format("%s%d: %s", marker, line_num, line))
  end

  return table.concat(result, "\n")
end

function M.get_word_under_cursor(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local line = vim.api.nvim_buf_get_lines(state.buf, state.line - 1, state.line, false)[1]
  if not line then
    return ""
  end

  local col = state.col
  local before = line:sub(1, col):match("[%w_]*$") or ""
  local after = line:sub(col + 1):match("^[%w_]*") or ""

  return before .. after
end

function M.get_recent_changes(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local changes = vim.fn.getchangelist(state.buf)
  if not changes or not changes[1] or #changes[1] == 0 then
    return "No recent changes"
  end

  local result = {}
  local max_changes = 10
  local changelist = changes[1]
  local start_idx = math.max(1, #changelist - max_changes + 1)

  for i = start_idx, #changelist do
    local change = changelist[i]
    if change.lnum and change.lnum > 0 then
      table.insert(result, string.format("Line %d", change.lnum))
    end
  end

  if #result == 0 then
    return "No recent changes"
  end

  return table.concat(result, ", ")
end

function M.get_marks(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local marks = vim.fn.getmarklist(state.buf)
  if not marks or #marks == 0 then
    return "No marks set"
  end

  local result = {}
  for _, mark in ipairs(marks) do
    if mark.mark:match("^'[a-zA-Z]$") and mark.pos[1] == state.buf then
      local line_num = mark.pos[2]
      local mark_char = mark.mark:sub(2, 2)
      table.insert(result, string.format("'%s: line %d", mark_char, line_num))
    end
  end

  if #result == 0 then
    return "No marks set"
  end

  return table.concat(result, ", ")
end

function M.get_search_pattern()
  local pattern = vim.fn.getreg("/")
  if not pattern or pattern == "" then
    return "No search pattern"
  end
  return pattern
end

return M
