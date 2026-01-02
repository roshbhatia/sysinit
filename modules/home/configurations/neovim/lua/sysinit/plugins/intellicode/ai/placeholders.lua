local M = {}
local context = require("sysinit.plugins.intellicode.ai.context")
local lsp = require("sysinit.plugins.intellicode.ai.lsp")

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

-- Get intelligent context for "this" - uses treesitter, LSP, or falls back to cursor
local function get_this_context(state)
  if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return string.format("@%s :%d", get_relative_path(state), state.line)
  end

  -- Try treesitter first
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if ok then
    local node = ts_utils.get_node_at_cursor()
    if node then
      -- Walk up to find a named node (function, class, method, etc.)
      while node do
        local node_type = node:type()
        -- Common semantic node types across languages
        if
          node_type:match("function")
          or node_type:match("method")
          or node_type:match("class")
          or node_type:match("struct")
          or node_type:match("interface")
          or node_type:match("declaration")
        then
          local start_row, start_col, end_row, end_col = node:range()
          local path = get_relative_path(state)
          -- Get node text for better context
          local lines = vim.api.nvim_buf_get_lines(state.buf, start_row, start_row + 1, false)
          if lines and lines[1] then
            local node_text = lines[1]:match("^%s*(.-)%s*$") -- trim whitespace
            if #node_text > 60 then
              node_text = node_text:sub(1, 57) .. "..."
            end
            return string.format("@%s :%d-%d (%s)", path, start_row + 1, end_row + 1, node_text)
          end
          return string.format("@%s :%d-%d", path, start_row + 1, end_row + 1)
        end
        node = node:parent()
      end
    end
  end

  -- Try LSP symbol information
  local params = vim.lsp.util.make_position_params()
  local lsp_result = lsp.request("textDocument/documentSymbol", params, 500)
  if lsp_result then
    local function find_symbol_at_position(symbols, line, col)
      for _, symbol in ipairs(symbols) do
        local range = symbol.range or symbol.location and symbol.location.range
        if range then
          local start_line = range.start.line
          local end_line = range["end"].line
          if line >= start_line and line <= end_line then
            -- Check if symbol has children (for nested symbols)
            if symbol.children then
              local child_symbol = find_symbol_at_position(symbol.children, line, col)
              if child_symbol then
                return child_symbol
              end
            end
            return symbol
          end
        end
      end
      return nil
    end

    local symbol = find_symbol_at_position(lsp_result, state.line - 1, state.col)
    if symbol then
      local path = get_relative_path(state)
      local range = symbol.range or symbol.location and symbol.location.range
      if range then
        return string.format(
          "@%s :%d-%d (%s)",
          path,
          range.start.line + 1,
          range["end"].line + 1,
          symbol.name
        )
      end
    end
  end

  -- Fallback to cursor position
  return string.format("@%s :%d", get_relative_path(state), state.line)
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

  return "@" .. dir
end

local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      return string.format("@%s :%d", get_relative_path(state), state.line)
    end,
  },
  {
    token = "@this",
    description = "Current semantic context (function/class/method via treesitter/LSP, falls back to cursor)",
    provider = get_this_context,
  },
  {
    token = "@folder",
    description = "Current folder path",
    provider = get_folder_context,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = context.get_visual_selection,
  },
  {
    token = "@osgrep",
    description = "osgrep results for current search (top matches)",
    provider = function(state)
      local q = context.get_search_pattern()
      if not q or q == "" then
        return ""
      end
      -- shell-escape the query
      local esc = vim.fn.shellescape(q)
      local cmd = "osgrep -n --max 10 " .. esc .. " . 2>/dev/null"
      local handle = io.popen(cmd)
      if not handle then
        return ""
      end
      local out = handle:read("*a") or ""
      handle:close()
      return out:gsub("^%s*(.-)%s*$", "%1")
    end,
  },
  {
    token = "@osgrep_paths",
    description = "Files matching current osgrep search",
    provider = function(state)
      local q = context.get_search_pattern()
      if not q or q == "" then
        return ""
      end
      local esc = vim.fn.shellescape(q)
      local cmd = "osgrep -n --max 50 " .. esc .. " . 2>/dev/null"
      local handle = io.popen(cmd)
      if not handle then
        return ""
      end
      local out = handle:read("*a") or ""
      handle:close()
      local seen = {}
      for line in out:gmatch("[^\r\n]+") do
        local p = line:match("^([^:]+):")
        if p and p ~= "" then
          seen[p] = true
        end
      end
      local paths = {}
      for p, _ in pairs(seen) do
        table.insert(paths, p)
      end
      table.sort(paths)
      return table.concat(paths, ", ")
    end,
  },
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
    token = "@visible",
    description = "Visible text in the current window",
    provider = context.get_visible_content,
  },
  {
    token = "@diagnostic",
    description = "Diagnostics for the current line",
    provider = context.get_line_diagnostics,
  },
  {
    token = "@diagnostics",
    description = "All diagnostics in the current buffer",
    provider = context.get_all_diagnostics,
  },
  {
    token = "@qflist",
    description = "Quickfix list entries",
    provider = context.get_quickfix_list,
  },
  {
    token = "@loclist",
    description = "Location list entries",
    provider = context.get_location_list,
  },
  {
    token = "@docs",
    description = "LSP hover documentation at cursor",
    provider = context.get_hover_docs,
  },
  {
    token = "@filetype",
    description = "Current buffer's filetype",
    provider = context.get_filetype,
  },
  {
    token = "@context",
    description = "Lines surrounding cursor (5 before/after)",
    provider = context.get_surrounding_lines,
  },
  {
    token = "@word",
    description = "Word under cursor",
    provider = context.get_word_under_cursor,
  },
  {
    token = "@changes",
    description = "Recent changes in buffer",
    provider = context.get_recent_changes,
  },
  {
    token = "@marks",
    description = "Marks set in buffer",
    provider = context.get_marks,
  },
  {
    token = "@search",
    description = "Current search pattern",
    provider = function()
      return context.get_search_pattern()
    end,
  },
  {
    token = "@git",
    description = "Git status for current repository",
    provider = function()
      return context.get_git_status()
    end,
  },
  {
    token = "@diff",
    description = "Git diff for current file",
    provider = function()
      return context.get_git_diff()
    end,
  },
  {
    token = "@imports",
    description = "Import statements in current file",
    provider = context.get_imports,
  },
  {
    token = "@clipboard",
    description = "System clipboard content",
    provider = function()
      return context.get_clipboard()
    end,
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
