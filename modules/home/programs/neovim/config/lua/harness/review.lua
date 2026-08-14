local M = {}

local session = { roots = {}, tabs = {} }

local INLINE_ABOVE = 40

local base = nil

---@param root string
---@return string
local function name(root)
  return vim.fn.fnamemodify(root, ":t")
end

---@param tab number|nil
---@return boolean
local function alive(tab)
  return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

local function prune()
  local roots, tabs = {}, {}
  for _, root in ipairs(session.roots) do
    if alive(session.tabs[root]) then
      roots[#roots + 1] = root
      tabs[root] = session.tabs[root]
    end
  end
  session.roots, session.tabs = roots, tabs
end

---@return boolean
function M.is_open()
  prune()
  return #session.roots > 0
end

---@return string[]
function M.roots()
  prune()
  return vim.deepcopy(session.roots)
end

---@return string|nil
function M.root()
  prune()
  local here = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    if session.tabs[root] == here then
      return root
    end
  end
  return session.roots[1]
end

---@param files integer
local function layout_for(files)
  local ok, config = pcall(require, "diffview.config")
  if not ok then
    return
  end
  local resolved = config.get_config()
  local wanted = files > INLINE_ABOVE and "diff1_plain" or "diff2_horizontal"
  if resolved.view.default.layout ~= wanted then
    resolved.view.default.layout = wanted
    if wanted == "diff1_plain" then
      vim.notify(string.format("Review: %d files, showing one window per file", files), vim.log.levels.INFO)
    end
  end
end

---@param roots string[]
---@return integer
local function changed_count(roots)
  local total = 0
  for _, root in ipairs(roots) do
    local out = vim.fn.systemlist({ "git", "-C", root, "status", "--porcelain", "--untracked-files=all" })
    if vim.v.shell_error == 0 then
      total = total + #out
    end
  end
  return total
end

---@param root string
---@param args string|nil
local function open_one(root, args)
  local rev = args or base or ""
  local ok, err = pcall(vim.cmd, string.format("DiffviewOpen -C%s %s", vim.fn.fnameescape(root), rev))
  if not ok then
    vim.notify(string.format("Review: %s would not open: %s", name(root), err), vim.log.levels.WARN)
    return
  end
  local tab = vim.api.nvim_get_current_tabpage()
  if session.tabs[root] == nil then
    session.roots[#session.roots + 1] = root
  end
  session.tabs[root] = tab
  vim.t[tab].review_repo = name(root)
end

---@param roots string[]
---@param args string|table<string, string>|nil
function M.open(roots, args)
  if #roots == 0 then
    return
  end
  layout_for(changed_count(roots))
  for _, root in ipairs(roots) do
    if not alive(session.tabs[root]) then
      open_one(root, type(args) == "table" and args[root] or args)
    end
  end
  prune()
  if alive(session.tabs[session.roots[1]]) then
    vim.api.nvim_set_current_tabpage(session.tabs[session.roots[1]])
  end
  local roots_open = M.roots()
  require("harness.notes").attach(roots_open, function(count)
    if count > 0 then
      vim.notify(string.format("Review: %d repositories, %d notes", #roots_open, count), vim.log.levels.INFO)
    end
  end)
end

---@param root string
---@param commit table
function M.open_revision(root, commit)
  local sha = commit and (commit.sha or commit.hash or commit.short)
  if sha == nil then
    return
  end
  M.open({ root }, sha .. "^!")
end

---@param step number
function M.cycle(step)
  prune()
  if #session.roots < 2 then
    return
  end
  local here = vim.api.nvim_get_current_tabpage()
  local at = 1
  for index, root in ipairs(session.roots) do
    if session.tabs[root] == here then
      at = index
    end
  end
  local next_at = (at - 1 + step) % #session.roots + 1
  local root = session.roots[next_at]
  vim.api.nvim_set_current_tabpage(session.tabs[root])
  vim.notify(string.format("Review: %s (%d of %d)", name(root), next_at, #session.roots), vim.log.levels.INFO)
end

function M.close()
  prune()
  local here = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    local tab = session.tabs[root]
    if alive(tab) then
      vim.api.nvim_set_current_tabpage(tab)
      pcall(vim.cmd, "DiffviewClose")
    end
  end
  session.roots, session.tabs = {}, {}
  if vim.api.nvim_tabpage_is_valid(here) then
    pcall(vim.api.nvim_set_current_tabpage, here)
  end
  pcall(function()
    require("harness.notes").detach()
  end)
end

function M.pick()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    if #roots == 0 then
      vim.notify("Review: no git repository under " .. gitrepo.workspace(), vim.log.levels.WARN)
      return
    end
    if #groups == 0 then
      local here = gitrepo.owning_root(vim.fs.normalize(vim.uv.cwd() or "."), roots) or roots[1]
      vim.notify(string.format("Review: nothing changed, showing %s", name(here)), vim.log.levels.INFO)
      M.open({ here })
      return
    end
    if #groups == 1 then
      M.open({ groups[1].root })
      return
    end

    local choices = { { label = string.format("All %d repositories", #groups), roots = nil } }
    for _, group in ipairs(groups) do
      choices[#choices + 1] = {
        label = string.format("%s  (%d changed)", name(group.root), #(group.files or {})),
        roots = { group.root },
      }
    end
    vim.ui.select(choices, {
      prompt = "Review",
      format_item = function(choice)
        return choice.label
      end,
    }, function(choice)
      if choice == nil then
        return
      end
      local wanted = choice.roots
      if wanted == nil then
        wanted = {}
        for _, group in ipairs(groups) do
          wanted[#wanted + 1] = group.root
        end
      end
      M.open(wanted)
    end)
  end)
end

---@return boolean
function M.here()
  prune()
  local tab = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    if session.tabs[root] == tab then
      return true
    end
  end
  return false
end

function M.toggle()
  if M.is_open() then
    return M.close()
  end

  local gitrepo = require("utils.gitrepo")
  local here = gitrepo.buffer_root() or gitrepo.cwd_root()
  if here == nil then
    return M.pick()
  end

  gitrepo.workspace_changes(function(groups)
    for _, group in ipairs(groups) do
      if group.root == here then
        return M.open({ here })
      end
    end
    if #groups > 0 then
      return M.pick()
    end
    vim.notify(string.format("Review: %s is clean", name(here)), vim.log.levels.INFO)
    M.open({ here })
  end)
end

---@param opts? { quiet?: boolean }
function M.refresh(opts)
  prune()
  local ok, lib = pcall(require, "diffview.lib")
  if ok then
    for _, view in ipairs(lib.views or {}) do
      if type(view.update_files) == "function" then
        pcall(function()
          view:update_files()
        end)
      end
    end
  end
  require("harness.notes").refresh(function(count)
    if not (opts and opts.quiet) then
      vim.notify(string.format("Review: reloaded, %d notes", count), vim.log.levels.INFO)
    end
  end)
end

function M.set_base()
  vim.ui.input({ prompt = "Compare the working tree back to: ", default = base or "" }, function(rev)
    if rev == nil then
      return
    end
    base = rev ~= "" and rev or nil
    local roots = M.roots()
    if #roots == 0 then
      return
    end
    M.close()
    M.open(roots)
  end)
end

---@param cb fun(root: string)
local function target(cb)
  local root = M.root()
  if root then
    return cb(root)
  end
  require("utils.gitrepo").resolve(cb, { ask = true })
end

function M.history()
  local path = vim.api.nvim_buf_get_name(0)
  if path ~= "" and vim.bo.buftype == "" then
    return vim.cmd(string.format("DiffviewFileHistory %s", vim.fn.fnameescape(path)))
  end
  target(function(root)
    vim.cmd(string.format("DiffviewFileHistory -C%s", vim.fn.fnameescape(root)))
  end)
end

function M.all()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    if #groups == 0 then
      vim.notify(
        #roots == 0 and "Review: no git repository under " .. gitrepo.workspace() or "Review: nothing changed",
        vim.log.levels.INFO
      )
      return
    end
    local wanted = {}
    for _, group in ipairs(groups) do
      wanted[#wanted + 1] = group.root
    end
    M.open(wanted)
  end)
end

return M
