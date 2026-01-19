local M = {}

-- Git root cache with invalidation on directory change
local git_root_cache = {}

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    git_root_cache = {}
  end,
})

-- Get git root directory with caching
local function get_git_root()
  local cwd = vim.fn.getcwd()
  if git_root_cache[cwd] ~= nil then
    return git_root_cache[cwd]
  end

  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    git_root_cache[cwd] = false
    return nil
  end

  local repo_root = handle:read("*a")
  handle:close()

  if repo_root then
    repo_root = repo_root:gsub("^%s*(.-)%s*$", "%1")
  end

  git_root_cache[cwd] = (repo_root and repo_root ~= "") and repo_root or false
  return git_root_cache[cwd] or nil
end

-- Strip git root from path
local function strip_git_root(path)
  local repo_root = get_git_root()
  if repo_root and path:sub(1, #repo_root) == repo_root then
    return path:sub(#repo_root + 2)
  end
  return path
end

-- LSP request helper (inlined from former lsp.lua)
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

function M.current_position()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  file = strip_git_root(file)

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
  local max_diags = 5
  for i = 1, math.min(#diags, max_diags) do
    local d = diags[i]
    local severity = vim.diagnostic.severity[d.severity] or "INFO"
    table.insert(grouped, string.format("[%s] Line %d: %s", severity, d.lnum + 1, d.message))
  end
  if #diags > max_diags then
    table.insert(grouped, string.format("... and %d more diagnostics", #diags - max_diags))
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

  return "@" .. strip_git_root(path)
end

function M.get_all_buffers_summary()
  local bufs = vim.api.nvim_list_bufs()
  local items = {}
  for _, b in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        table.insert(items, strip_git_root(name))
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
  local top_line = vim.fn.line("w0")
  local bottom_line = vim.fn.line("w$")
  local bufnr = state.buf
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bottom_line, false)
  return table.concat(lines, "\n")
end

function M.get_hover_docs()
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
  return vim.bo[state.buf].filetype
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

function M.get_git_status()
  -- Get git status for current buffer's file
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    return "Not in a git repository or no file"
  end

  local result = vim.fn.system(
    "git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(filepath, ":h")) .. " status --short --branch 2>/dev/null"
  )

  if vim.v.shell_error ~= 0 then
    return "Not in a git repository"
  end

  if result == "" or result == "## " then
    return "No changes"
  end

  return vim.trim(result)
end

function M.get_git_diff()
  -- Get git diff for current buffer's file
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    return "No file"
  end

  local repo_root = get_git_root()
  if not repo_root then
    return "Not in a git repository"
  end

  -- Get relative path from repo root
  local rel_path = strip_git_root(filepath)

  local result = vim.fn.system(
    "git -C " .. vim.fn.shellescape(repo_root) .. " diff " .. vim.fn.shellescape(rel_path) .. " 2>/dev/null"
  )

  if vim.v.shell_error ~= 0 or result == "" then
    return "No changes in current file"
  end

  return vim.trim(result)
end

return M
