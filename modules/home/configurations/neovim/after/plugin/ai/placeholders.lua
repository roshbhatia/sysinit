local M = {}
local context = require("sysinit.utils.ai.context")

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

local function get_buffer_path(state)
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
  local path = get_buffer_path(state)
  if not path then
    return ""
  end
  return normalize_path(path, true)
end

local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

local function get_folder_context(state)
  local path = get_buffer_path(state)
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
    provider = context.get_all_buffers_summary,
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
    provider = context.get_git_diff,
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
    provider = context.get_git_status,
  },
  {
    token = "@loclist",
    description = "Location list entries",
    provider = context.get_location_list,
  },
  {
    token = "@marks",
    description = "Marks set in buffer",
    provider = context.get_marks,
  },
  {
    token = "@qflist",
    description = "Quickfix list entries",
    provider = context.get_quickfix_list,
  },
  {
    token = "@search",
    description = "Current search pattern",
    provider = context.get_search_pattern,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = context.get_visual_selection,
  },
  {
    token = "@word",
    description = "Word under cursor",
    provider = context.get_word_under_cursor,
  },
}

function M.apply_placeholders(input, state)
  if not input or input == "" then
    return input
  end

  state = state or context.current_position()
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
