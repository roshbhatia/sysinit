local M = {}
local context = require("sysinit.plugins.intellicode.ai.context")
local ts = require("sysinit.plugins.intellicode.ai.treesitter")
local specify = require("sysinit.plugins.intellicode.ai.specify")

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

-- Helper function to run ast-grep with proper error handling and formatting
local function run_astgrep(pattern, lang, options)
  options = options or {}
  local cmd_parts = { "ast-grep" }

  if lang then
    table.insert(cmd_parts, string.format("-l %s", lang))
  end

  table.insert(cmd_parts, string.format("-p '%s'", pattern:gsub("'", "'\\''")))

  if options.json then
    table.insert(cmd_parts, "--json=stream")
  end

  if options.files_only then
    table.insert(cmd_parts, "--files-with-matches")
  end

  table.insert(cmd_parts, "2>/dev/null")

  local cmd = table.concat(cmd_parts, " ")
  local handle = io.popen(cmd)
  if not handle then
    return nil, "ast-grep not available"
  end

  local output = handle:read("*a")
  local success = handle:close()

  if not success or output == "" then
    return nil, "No matches found"
  end

  return output, nil
end

-- Preview ast-grep results in a floating window
local function preview_astgrep_results(pattern, lang)
  local output, err = run_astgrep(pattern, lang, { json = false })
  if err then
    vim.notify("ast-grep: " .. err, vim.log.levels.WARN)
    return
  end

  -- Create a scratch buffer for preview
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(output, "\n")

  -- Limit preview to 50 lines
  if #lines > 50 then
    table.insert(lines, 51, "... (" .. (#lines - 50) .. " more lines)")
    lines = vim.list_slice(lines, 1, 51)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "astgrep")

  -- Calculate window size
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.8))

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = string.format(" ast-grep: %s ", pattern),
    title_pos = "center",
  })

  -- Set keymaps for the preview window
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "y", function()
    vim.fn.setreg("+", output)
    vim.notify("Copied to clipboard", vim.log.levels.INFO)
  end, { buffer = buf, silent = true, desc = "Yank results to clipboard" })

  return output
end

local PLACEHOLDERS = {
  {
    token = "@cursor",
    description = "Cursor position (file:line)",
    provider = function(state)
      return string.format("%s:%d", get_relative_path(state), state.line)
    end,
  },
  {
    token = "@selection",
    description = "Selected text",
    provider = context.get_visual_selection,
  },
  {
    token = "@buffer",
    description = "Current buffer's file path",
    provider = get_relative_path,
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
    token = "@codeactions",
    description = "Available LSP code action titles",
    provider = context.get_code_actions,
  },
  {
    token = "@function",
    description = "Current function context (via treesitter)",
    provider = ts.get_current_function,
  },
  {
    token = "@class",
    description = "Current class/type context (via treesitter)",
    provider = ts.get_current_class,
  },
  {
    token = "@node",
    description = "Current treesitter node type and text",
    provider = ts.get_current_node,
  },
  {
    token = "@symbols",
    description = "All symbols (functions, classes) in buffer",
    provider = ts.get_all_symbols,
  },
  {
    token = "@imports",
    description = "Import/require statements in buffer",
    provider = ts.get_imports,
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
  -- Specify-specific placeholders
  {
    token = "@spec",
    description = "Current specification file (from .specify/specs/*/spec.md)",
    provider = function()
      return specify.read_spec_file("spec.md") or ""
    end,
  },
  {
    token = "@plan",
    description = "Current implementation plan (from .specify/specs/*/plan.md)",
    provider = function()
      return specify.read_spec_file("plan.md") or ""
    end,
  },
  {
    token = "@tasks",
    description = "Current task list (from .specify/specs/*/tasks.md)",
    provider = function()
      return specify.read_spec_file("tasks.md") or ""
    end,
  },
  {
    token = "@constitution",
    description = "Project constitution and principles (from .specify/memory/constitution.md)",
    provider = function()
      return specify.get_constitution() or ""
    end,
  },
  {
    token = "@astgrep",
    description = "AST-based pattern search results for current file",
    provider = function(state)
      local context = require("sysinit.plugins.intellicode.ai.context")
      local path = vim.api.nvim_buf_get_name(state.buf)

      if path == "" then
        return "No file open"
      end

      -- Use ast-grep to find structural patterns in current file
      local handle = io.popen(string.format("ast-grep scan '%s' 2>/dev/null", path))
      if not handle then
        return "ast-grep not available"
      end

      local result = handle:read("*a")
      handle:close()

      return result ~= "" and result or "No patterns found"
    end,
  },
  {
    token = "@astgrep-pattern",
    description = "Search codebase for AST pattern (usage: @astgrep-pattern:your-pattern)",
    provider = function(state)
      -- This is a dynamic placeholder that expects a pattern argument
      -- Will be expanded in apply_placeholders with regex matching
      return ""
    end,
  },
  {
    token = "@astgrep-lang",
    description = "Language-specific AST search (usage: @astgrep-lang:typescript:pattern)",
    provider = function(state)
      return ""
    end,
  },
  {
    token = "@astgrep-preview",
    description = "Preview ast-grep results before submitting (usage: @astgrep-preview:pattern)",
    provider = function(state)
      return ""
    end,
  },
}

-- Export preview function for use in keymaps
M.preview_astgrep = preview_astgrep_results

function M.apply_placeholders(input)
  if not input or input == "" then
    return input
  end
  local state = context.current_position()
  local result = input

  -- Handle ast-grep preview placeholders (shows preview then expands)
  result = result:gsub("@astgrep%-preview:([^%s]+)", function(pattern)
    local output = preview_astgrep_results(pattern, nil)
    return output or "Preview cancelled"
  end)

  -- Handle ast-grep preview with language
  result = result:gsub("@astgrep%-preview%-lang:([^:]+):([^%s]+)", function(lang, pattern)
    local output = preview_astgrep_results(pattern, lang)
    return output or "Preview cancelled"
  end)

  -- Handle dynamic ast-grep-pattern placeholders
  result = result:gsub("@astgrep%-pattern:([^%s]+)", function(pattern)
    local output, err = run_astgrep(pattern, nil, {})
    if err then
      return err
    end
    return output
  end)

  -- Handle language-specific ast-grep searches
  result = result:gsub("@astgrep%-lang:([^:]+):([^%s]+)", function(lang, pattern)
    local output, err = run_astgrep(pattern, lang, {})
    if err then
      return err
    end
    return output
  end)

  -- Handle regular placeholders
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
