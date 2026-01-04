local M = {}
local context = require("sysinit.plugins.intellicode.ai.context")

local function get_relative_path(state)
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

  return path
end

local function escape_lua_pattern(s)
  return (s:gsub("(%W)", "%%%1"))
end

-- Get the current folder path
local function get_folder_context(state)
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

  -- Get directory path
  local dir = vim.fn.fnamemodify(path, ":h")

  if repo_root and repo_root ~= "" then
    dir = dir:sub(#repo_root + 2)
  end

  return "+" .. dir
end

local PLACEHOLDERS = {
  {
    token = "+buffer",
    description = "Current buffer's file path",
    provider = function(state)
      local path = get_relative_path(state)
      return path ~= "" and "+" .. path or ""
    end,
  },
  {
    token = "+buffers",
    description = "List of open buffers",
    provider = context.get_all_buffers_summary,
  },
  {
    token = "+changes",
    description = "Recent changes in buffer",
    provider = context.get_recent_changes,
  },
  {
    token = "+clipboard",
    description = "System clipboard content",
    provider = function()
      return context.get_clipboard()
    end,
  },
  {
    token = "+context",
    description = "Lines surrounding cursor (5 before/after)",
    provider = context.get_surrounding_lines,
  },
  {
    token = "+cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      return string.format("+%s :%d", get_relative_path(state), state.line)
    end,
  },
  {
    token = "+diagnostic",
    description = "Diagnostics for the current line",
    provider = function(state)
      return context.get_line_diagnostics(state)
    end,
  },
  {
    token = "+diagnostics",
    description = "All diagnostics in the current buffer",
    provider = function(state)
      return context.get_all_diagnostics(state)
    end,
  },
  {
    token = "+diff",
    description = "Git diff for current file",
    provider = function()
      return context.get_git_diff()
    end,
  },
  {
    token = "+docs",
    description = "LSP hover documentation at cursor",
    provider = context.get_hover_docs,
  },
  {
    token = "+filetype",
    description = "Current buffer's filetype",
    provider = context.get_filetype,
  },
  {
    token = "+folder",
    description = "Current folder path",
    provider = get_folder_context,
  },
  {
    token = "+git",
    description = "Git status for current repository",
    provider = function()
      return context.get_git_status()
    end,
  },
  {
    token = "+imports",
    description = "Import statements in current file",
    provider = context.get_imports,
  },
  {
    token = "+loclist",
    description = "Location list entries",
    provider = context.get_location_list,
  },
  {
    token = "+marks",
    description = "Marks set in buffer",
    provider = context.get_marks,
  },
  {
    token = "+qflist",
    description = "Quickfix list entries",
    provider = context.get_quickfix_list,
  },
  {
    token = "+search",
    description = "Current search pattern",
    provider = function()
      return context.get_search_pattern()
    end,
  },
  {
    token = "+selection",
    description = "Selected text",
    provider = context.get_visual_selection,
  },
  {
    token = "+visible",
    description = "Visible text in the current window",
    provider = context.get_visible_content,
  },
  {
    token = "+word",
    description = "Word under cursor",
    provider = context.get_word_under_cursor,
  },
}

function M.apply_placeholders(input)
  if not input or input == "" then
    return input
  end
  local state = context.current_position()
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

return M
