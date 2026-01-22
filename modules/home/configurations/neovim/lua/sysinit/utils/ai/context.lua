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

-- Track last focused source window for accurate context capture
local last_source_win = nil

-- Filetypes to exclude from source window tracking (UI/special buffers)
local excluded_filetypes = {
  snacks_terminal = true,
  ai_terminals_input = true,
  ["neo-tree"] = true,
  NvimTree = true,
  Outline = true,
  qf = true,
  TelescopePrompt = true,
  TelescopeResults = true,
  lazy = true,
  mason = true,
  notify = true,
  noice = true,
  fidget = true,
  trouble = true,
  Trouble = true,
  dap_repl = true,
  dapui_watches = true,
  dapui_stacks = true,
  dapui_breakpoints = true,
  dapui_scopes = true,
  dapui_console = true,
  oil = true,
  fugitive = true,
  git = true,
  gitcommit = true,
  DiffviewFiles = true,
  DiffviewFileHistory = true,
  undotree = true,
  spectre_panel = true,
}

-- Check if window/buffer is a valid source (not a UI element)
local function is_source_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype

  -- Exclude special filetypes
  if excluded_filetypes[ft] then
    return false
  end

  -- Exclude floating windows (popups, hover, etc)
  local config = vim.api.nvim_win_get_config(win)
  if config.relative ~= "" then
    return false
  end

  -- Accept normal buffers and help buffers
  return bt == "" or bt == "help" or bt == "acwrite"
end

-- Track source window on focus changes
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_source_window(win) then
      last_source_win = win
    end
  end,
})

-- Capture current editor state
function M.capture()
  local win, buf

  -- Priority 1: Use tracked source window if still valid
  if last_source_win and is_source_window(last_source_win) then
    win = last_source_win
    buf = vim.api.nvim_win_get_buf(win)
  else
    -- Priority 2: Try alternate window (vim's # window)
    local alt_winnr = vim.fn.winnr("#")
    if alt_winnr ~= 0 then
      local alt_win = vim.fn.win_getid(alt_winnr)
      if alt_win ~= 0 and is_source_window(alt_win) then
        win = alt_win
        buf = vim.api.nvim_win_get_buf(win)
      end
    end

    -- Priority 3: Filter all windows and find first valid source
    if not win then
      local wins = vim.tbl_filter(is_source_window, vim.api.nvim_list_wins())
      if #wins > 0 then
        win = wins[1]
        buf = vim.api.nvim_win_get_buf(win)
      end
    end

    -- Priority 4: Fallback to current window
    if not win then
      win = vim.api.nvim_get_current_win()
      buf = vim.api.nvim_win_get_buf(win)
    end
  end

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
