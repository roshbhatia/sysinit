local M = {}

-- Check if buffer is a real file (not terminal, scratch, etc)
function M.is_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end
  local bt = vim.bo[buf].buftype
  return bt == "" or bt == "acwrite"
end

-- Git root cache with invalidation
local git_root_cache = {}

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    git_root_cache = {}
  end,
})

-- Get git root with caching
function M.get_git_root()
  local cwd = vim.fn.getcwd()
  if git_root_cache[cwd] ~= nil then
    return git_root_cache[cwd]
  end

  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    git_root_cache[cwd] = false
    return nil
  end

  local root = handle:read("*a")
  handle:close()

  if root then
    root = root:gsub("^%s*(.-)%s*$", "%1")
  end

  git_root_cache[cwd] = (root and root ~= "") and root or false
  return git_root_cache[cwd] or nil
end

-- Make path relative to git root
function M.strip_git_root(path)
  local root = M.get_git_root()
  if root and path:sub(1, #root) == root then
    local remainder = path:sub(#root + 1)
    return remainder:match("^/(.*)$") or remainder
  end
  return path
end

-- Get visual selection range
function M.get_selection_range(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  -- Check if in visual mode
  local mode = vim.fn.mode()
  if not mode:match("[vV\22]") then
    return nil
  end

  -- Exit visual to get marks, then restore
  vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
  local from = vim.api.nvim_buf_get_mark(buf, "<")
  local to = vim.api.nvim_buf_get_mark(buf, ">")
  vim.cmd("normal! gv")

  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end

  local kind_map = {
    v = "char",
    V = "line",
    ["\22"] = "block",
  }

  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind_map[mode:sub(1, 1)] or "char",
  }
end

-- Capture current editor state
function M.capture()
  -- Find most recent non-terminal window
  local wins = vim.tbl_filter(function(w)
    if not vim.api.nvim_win_is_valid(w) then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(w)
    local ft = vim.bo[buf].filetype
    return ft ~= "snacks_terminal" and ft ~= "ai_terminals_input"
  end, vim.api.nvim_list_wins())

  local win = wins[1]
  if not win or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)

  -- Use window-local cwd if valid, otherwise fall back to global cwd
  local cwd
  local ok, result = pcall(vim.fn.getcwd, win)
  if ok and result then
    cwd = vim.fs.normalize(result)
  else
    cwd = vim.fs.normalize(vim.fn.getcwd())
  end

  return {
    win = win,
    buf = buf,
    cwd = cwd,
    row = cursor[1],
    col = cursor[2] + 1,
    range = M.get_selection_range(buf),
  }
end

-- Context class: captures state and caches provider results
local Context = {}
Context.__index = Context

function Context.new()
  local self = setmetatable({}, Context)
  self.ctx = M.capture()
  self.cache = {}
  return self
end

-- Get a context value with optional fallbacks
-- Usage: ctx:get("position|selection") tries position first, then selection
-- @param name string Comma-separated list of provider names (e.g., "position|selection")
-- @return string|nil The first non-nil provider result
function Context:get(name)
  local names = vim.split(name, "|", { plain = true })
  for _, n in ipairs(names) do
    if self.cache[n] == nil then
      local providers = require("sysinit.utils.ai.placeholders").providers
      local fn = providers[n]
      local result = fn and fn(self.ctx) or false
      self.cache[n] = (result and result ~= "") and result or false
    end
    if self.cache[n] then
      return self.cache[n]
    end
  end
  return nil
end

M.Context = Context
M.new = Context.new

return M
