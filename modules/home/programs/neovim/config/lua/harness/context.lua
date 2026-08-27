---@class harness.SelectionRange
---@field from integer[]
---@field to integer[]
---@field kind string

---@class harness.EditorState
---@field win integer
---@field buf integer
---@field cwd string
---@field row integer
---@field col integer
---@field range harness.SelectionRange?

local M = {}

function M.is_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end
  local bt = vim.bo[buf].buftype
  return bt == "" or bt == "acwrite"
end

local git_root_cache = {}

local function physical_path(path)
  local normalized = vim.fs.normalize(path)
  local resolved = vim.uv.fs_realpath(normalized)
  if resolved then
    return resolved
  end
  local parent = vim.fn.fnamemodify(normalized, ":h")
  local physical_parent = vim.uv.fs_realpath(parent)
  if physical_parent then
    return vim.fs.joinpath(physical_parent, vim.fn.fnamemodify(normalized, ":t"))
  end
  return normalized
end

local function prewarm_git_root(cwd)
  if git_root_cache[cwd] ~= nil then
    return
  end
  vim.system(
    { "git", "rev-parse", "--show-toplevel" },
    { cwd = cwd, text = true },
    vim.schedule_wrap(function(obj)
      if git_root_cache[cwd] == nil then
        if obj.code == 0 then
          local root = vim.trim(obj.stdout or "")
          git_root_cache[cwd] = (root ~= "") and root or false
        else
          git_root_cache[cwd] = false
        end
      end
    end)
  )
end

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    git_root_cache = {}
    prewarm_git_root(vim.fn.getcwd())
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local ok, cwd = pcall(vim.fn.getcwd)
    if ok and cwd and cwd ~= "" then
      prewarm_git_root(cwd)
    end
  end,
})

function M.get_git_root(cwd)
  cwd = physical_path(cwd or vim.fn.getcwd())
  if git_root_cache[cwd] ~= nil then
    return git_root_cache[cwd] or nil
  end

  local obj = vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, text = true }):wait(1500)
  if not obj or obj.code == nil or obj.code ~= 0 then
    git_root_cache[cwd] = false
    return nil
  end

  local root = vim.trim(obj.stdout or "")
  git_root_cache[cwd] = (root ~= "") and root or false
  return git_root_cache[cwd] or nil
end

function M.strip_git_root(path, root)
  root = root or M.get_git_root(vim.fn.fnamemodify(path, ":h"))
  if root then
    root = physical_path(root)
    local physical = physical_path(path)
    if physical == root then
      return "."
    end
    if vim.startswith(physical, root .. "/") then
      return physical:sub(#root + 2)
    end
  end
  return path
end

function M.get_selection_range(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  local mode = vim.fn.mode()
  if not mode:match("[vV\22]") then
    return nil
  end

  vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
  local from = vim.api.nvim_buf_get_mark(buf, "<")
  local to = vim.api.nvim_buf_get_mark(buf, ">")
  vim.cmd("normal! gv")

  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end

  local kind_map = { v = "char", V = "line", ["\22"] = "block" }
  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind_map[mode:sub(1, 1)] or "char",
  }
end

local last_source_win = nil

local excluded_filetypes = {
  snacks_terminal = true,
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
  ai_terminals_input = true,
}

local function is_source_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype
  if excluded_filetypes[ft] then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return false
  end
  return bt == "" or bt == "help" or bt == "acwrite"
end

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_source_window(win) then
      last_source_win = win
    end
  end,
})

---@return harness.EditorState
function M.capture()
  local win, buf

  local cur_win = vim.api.nvim_get_current_win()
  if is_source_window(cur_win) then
    win = cur_win
    buf = vim.api.nvim_win_get_buf(win)
  elseif last_source_win and is_source_window(last_source_win) then
    win = last_source_win
    buf = vim.api.nvim_win_get_buf(win)
  else
    local alt_winnr = vim.fn.winnr("#")
    if alt_winnr ~= 0 then
      local alt_win = vim.fn.win_getid(alt_winnr)
      if alt_win ~= 0 and is_source_window(alt_win) then
        win = alt_win
        buf = vim.api.nvim_win_get_buf(win)
      end
    end

    if not win then
      local wins = vim.tbl_filter(is_source_window, vim.api.nvim_list_wins())
      if #wins > 0 then
        win = wins[1]
        buf = vim.api.nvim_win_get_buf(win)
      end
    end

    if not win then
      win = vim.api.nvim_get_current_win()
      buf = vim.api.nvim_win_get_buf(win)
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(win)

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

local Context = {}
Context.__index = Context

function Context.new()
  return setmetatable({ ctx = M.capture(), cache = {} }, Context)
end

function Context:get(name)
  local names = vim.split(name, "|", { plain = true })
  for _, n in ipairs(names) do
    if self.cache[n] == nil then
      local providers = require("harness.placeholders").providers
      local fn = providers[n]
      local ok, result = pcall(function()
        return fn and fn(self.ctx) or false
      end)
      if not ok then
        result = false
      end
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

---@return harness.EditorState
function M.from_marks(buf, marks)
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(cur_win)

  local cwd
  local ok, result = pcall(M.get_git_root)
  if ok and type(result) == "string" then
    cwd = vim.fs.normalize(result)
  else
    cwd = vim.fs.normalize(vim.fn.getcwd())
  end

  local ctx = {
    win = cur_win,
    buf = buf or cur_buf,
    cwd = cwd,
    row = cursor[1],
    col = cursor[2] + 1,
    range = marks,
  }
  return setmetatable({ ctx = ctx, cache = {} }, Context)
end

return M
