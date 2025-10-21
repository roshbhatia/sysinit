local M = {}

-- Execute ast-grep command and return results
function M.execute(cmd, args)
  local full_cmd = string.format("ast-grep %s %s 2>/dev/null", cmd, args or "")
  local handle = io.popen(full_cmd)

  if not handle then
    return nil, "Failed to execute ast-grep"
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    return nil, "ast-grep command failed"
  end

  return result, nil
end

-- Search for pattern in current file
function M.search_current_file(pattern)
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if path == "" then
    return nil, "No file open"
  end

  local args = string.format("-p '%s' '%s'", pattern, path)
  return M.execute("search", args)
end

-- Search for pattern in project
function M.search_project(pattern, file_pattern)
  local cwd = vim.fn.getcwd()
  local args = string.format("-p '%s'", pattern)

  if file_pattern then
    args = args .. string.format(" -g '%s'", file_pattern)
  end

  return M.execute("search", args)
end

-- Rewrite code using pattern and replacement
function M.rewrite(pattern, replacement, path)
  local args = string.format("-p '%s' -r '%s' '%s'", pattern, replacement, path or ".")
  return M.execute("rewrite", args)
end

-- Scan for patterns defined in sgconfig.yml
function M.scan(path)
  local args = path and string.format("'%s'", path) or ""
  return M.execute("scan", args)
end

-- Get language-specific search
function M.search_lang(lang, pattern, file_pattern)
  local args = string.format("-l %s -p '%s'", lang, pattern)

  if file_pattern then
    args = args .. string.format(" -g '%s'", file_pattern)
  end

  return M.execute("search", args)
end

-- Test if ast-grep is available
function M.is_available()
  local handle = io.popen("which ast-grep 2>/dev/null")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  handle:close()

  return result ~= ""
end

return M
