local M = {}

local nio_available, nio = pcall(require, "nio")

function M.request(method, params, timeout)
  if nio_available and nio.lsp then
    local clients = nio.lsp.get_clients({ bufnr = 0, method = method })
    if #clients == 0 then
      return nil
    end

    local err, result =
      clients[1].request[method:gsub("/", "_"):gsub("$", "__")](params, 0, { timeout = timeout or 500 })
    if err or not result then
      return nil
    end
    return result
  end

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
  local top_line = vim.fn.line("w0")
  local bottom_line = vim.fn.line("w$")
  local bufnr = state.buf
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bottom_line, false)
  return table.concat(lines, "\n")
end

function M.get_hover_docs()
  local params = vim.lsp.util.make_position_params()
  local result = M.request("textDocument/hover", params)
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

function M.get_git_status()
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
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  if filepath == "" then
    return "No file"
  end

  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if repo_root == "" then
    return "Not in a git repository"
  end

  local rel_path = filepath:sub(#repo_root + 2)

  local result = vim.fn.system(
    "git -C " .. vim.fn.shellescape(repo_root) .. " diff " .. vim.fn.shellescape(rel_path) .. " 2>/dev/null"
  )

  if vim.v.shell_error ~= 0 or result == "" then
    return "No changes in current file"
  end

  return vim.trim(result)
end

function M.get_imports(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ""
  end

  local filetype = vim.api.nvim_buf_get_option(state.buf, "filetype")
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, 100, false)
  local imports = {}

  local patterns = {
    python = "^import%s+.+$|^from%s+.+import",
    javascript = "^import%s+.+$|^const%s+.+%s*=%s*require",
    typescript = "^import%s+.+$|^const%s+.+%s*=%s*require",
    lua = "^local%s+.+%s*=%s*require",
    go = "^import%s+",
    rust = "^use%s+",
    java = "^import%s+",
  }

  local pattern = patterns[filetype]
  if not pattern then
    return ""
  end

  for pat in vim.gsplit(pattern, "|", { plain = true }) do
    for _, line in ipairs(lines) do
      if line:match(pat) then
        table.insert(imports, line)
      end
    end
  end

  if #imports == 0 then
    return "No imports found"
  end

  return table.concat(imports, "\n")
end

function M.get_clipboard()
  local clipboard = vim.fn.getreg("+")
  if not clipboard or clipboard == "" then
    clipboard = vim.fn.getreg("*")
  end
  if not clipboard or clipboard == "" then
    return "Clipboard empty"
  end
  return clipboard
end

local git_root_cache = {}

local function get_git_root()
  local cwd = vim.fn.getcwd()
  if git_root_cache[cwd] then
    return git_root_cache[cwd]
  end

  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    return nil
  end

  local root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  git_root_cache[cwd] = (root and root ~= "") and root or nil
  return git_root_cache[cwd]
end

local function validate_state(state)
  return state and state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function get_buffer_path_internal(state)
  if not validate_state(state) then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(state.buf)
  return path ~= "" and path or nil
end

local function normalize_path(path, strip_root)
  if not path or path == "" then
    return ""
  end
  if not strip_root then
    return path
  end

  local git_root = get_git_root()
  if not git_root then
    return path
  end

  local git_root_normalized = git_root:gsub("/$", "")
  if path:sub(1, #git_root_normalized) == git_root_normalized then
    local remainder = path:sub(#git_root_normalized + 1)
    return remainder:match("^/(.*)$") or remainder
  end

  return path
end

local function get_relative_path(state)
  local path = get_buffer_path_internal(state)
  if not path then
    return ""
  end
  return normalize_path(path, true)
end

local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

local function get_folder_context(state)
  local path = get_buffer_path_internal(state)
  if not path then
    return ""
  end

  local dir = vim.fn.fnamemodify(path, ":h")
  return normalize_path(dir, true)
end

local PLACEHOLDERS = {
  {
    token = "@buffer",
    description = "Current buffer's file path",
    provider = function(state)
      local path = get_relative_path(state)
      return path ~= "" and "@" .. path or ""
    end,
  },
  {
    token = "@buffers",
    description = "List of open buffers",
    provider = M.get_all_buffers_summary,
  },
  {
    token = "@cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      local path = get_relative_path(state)
      if not state or not state.line or path == "" then
        return ""
      end
      return string.format("@%s:%d", path, state.line)
    end,
  },
  {
    token = "@diagnostics",
    description = "Diagnostics for the current buffer",
    provider = function(state)
      if not validate_state(state) or not state.line then
        return ""
      end
      local diags = vim.diagnostic.get(state.buf, { lnum = state.line - 1 })
      local severity_names = {
        [vim.diagnostic.severity.ERROR] = "ERROR",
        [vim.diagnostic.severity.WARN] = "WARN",
        [vim.diagnostic.severity.INFO] = "INFO",
        [vim.diagnostic.severity.HINT] = "HINT",
      }
      local lines = {}
      for _, diag in ipairs(diags) do
        local severity = severity_names[diag.severity] or tostring(diag.severity)
        table.insert(lines, string.format("[%s] %s", severity, diag.message))
      end
      return table.concat(lines, "\n")
    end,
  },
  {
    token = "@diff",
    description = "Git diff for current file",
    provider = M.get_git_diff,
  },
  {
    token = "@folder",
    description = "Current folder path",
    provider = function(state)
      local dir = get_folder_context(state)
      return dir ~= "" and "@" .. dir or ""
    end,
  },
  {
    token = "@git",
    description = "Git status for current repository",
    provider = M.get_git_status,
  },
  {
    token = "@loclist",
    description = "Location list entries",
    provider = M.get_location_list,
  },
  {
    token = "@marks",
    description = "Marks set in buffer",
    provider = M.get_marks,
  },
  {
    token = "@qflist",
    description = "Quickfix list entries",
    provider = M.get_quickfix_list,
  },
  {
    token = "@search",
    description = "Current search pattern",
    provider = M.get_search_pattern,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = M.get_visual_selection,
  },
  {
    token = "@word",
    description = "Word under cursor",
    provider = M.get_word_under_cursor,
  },
}

function M.apply_placeholders(input, state)
  if not input or input == "" then
    return input
  end

  state = state or M.current_position()
  local result = input

  for _, ph in ipairs(PLACEHOLDERS) do
    if result:find(ph.token, 1, true) then
      local ok, value = pcall(ph.provider, state)
      result = result:gsub(escape_lua_pattern(ph.token), ok and value or "")
    end
  end

  return result
end

M.placeholder_descriptions = vim.tbl_map(function(p)
  return { token = p.token, description = p.description }
end, PLACEHOLDERS)

return M
