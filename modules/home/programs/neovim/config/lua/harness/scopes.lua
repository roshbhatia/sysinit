-- The review's scope list: the workspace diff, then each repository's recent commits.
local M = {}

-- Ten per repository: far enough back to reach the change under review, short enough
-- that the list still fits under a diff.
local PER_REPO = 10

-- git's empty tree, which is the only left side a root commit has.
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

-- `id` is what tells a step whether the quickfix still shows the scopes or has been
-- replaced by a file list, since both live in the same stack.
local state = { id = nil, said = "workspace" }

local function qf_winid()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      return win.winid
    end
  end
  return nil
end

--- Whether the quickfix currently shows the scope list.
---@return boolean
function M.is_shown()
  return state.id ~= nil and vim.fn.getqflist({ id = 0 }).id == state.id
end

--- Forget the chosen scope, for a caller that opened the workspace diff itself.
function M.reset()
  state.said = "workspace"
end

--- The repositories to list commits for: the open review's, else the workspace's.
---@param cb fun(roots: string[])
local function scope_roots(cb)
  local roots = require("harness.api").review_roots()
  if #roots > 0 then
    return cb(roots)
  end
  require("utils.gitrepo").workspace_roots(cb)
end

--- Parse one `ws log` row: root, sha, short sha, first parent, subject.
---@param line string
---@return table|nil
local function row(line)
  local root, sha, short, parent, subject = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
  if root == nil or sha == "" then
    return nil
  end
  return { kind = "commit", root = root, sha = sha, short = short, parent = parent, subject = subject }
end

--- Every root's commits in one call, from the same command that answers `ws roots`. The
--- roots go in on stdin, so the review's order survives.
---@param roots string[]
---@param cb fun(commits: table[]|nil)
local function commits_via_ws(roots, cb)
  if vim.fn.executable("ws") ~= 1 then
    return cb(nil)
  end
  vim.system({ "ws", "log", "-n", tostring(PER_REPO), "-" }, {
    text = true,
    stdin = table.concat(roots, "\n") .. "\n",
  }, function(res)
    if res.code ~= 0 then
      return vim.schedule(function()
        cb(nil)
      end)
    end
    local found = {}
    for line in (res.stdout or ""):gmatch("[^\n]+") do
      found[#found + 1] = row(line)
    end
    vim.schedule(function()
      cb(found)
    end)
  end)
end

--- One repository's recent commits, newest first.
---@param root string
---@param cb fun(commits: table[])
local function commits(root, cb)
  vim.system({
    "git",
    "-C",
    root,
    "log",
    "--max-count=" .. PER_REPO,
    "--format=%H%x1f%h%x1f%P%x1f%s",
  }, { text = true }, function(res)
    local found = {}
    if res.code == 0 then
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local sha, short, parents, subject = line:match("^([^\31]*)\31([^\31]*)\31([^\31]*)\31(.*)$")
        if sha and sha ~= "" then
          found[#found + 1] = {
            kind = "commit",
            root = root,
            sha = sha,
            short = short,
            -- The first parent, so a merge reads as what it brought in, and the empty
            -- tree when there is none, since `<sha>^` does not resolve on a root commit.
            parent = parents:match("^(%S+)") or EMPTY_TREE,
            subject = subject,
          }
        end
      end
    end
    vim.schedule(function()
      cb(found)
    end)
  end)
end

--- One `git log` per repository, for a box with no `ws` on PATH.
---@param roots string[]
---@param cb fun(commits: table[])
local function all_commits_via_git(roots, cb)
  local found, pending = {}, #roots
  for index, root in ipairs(roots) do
    commits(root, function(list)
      found[index] = list
      pending = pending - 1
      if pending == 0 then
        local flat = {}
        for at = 1, #roots do
          for _, commit in ipairs(found[at] or {}) do
            flat[#flat + 1] = commit
          end
        end
        cb(flat)
      end
    end)
  end
end

--- Every repository's commits, grouped in the order the roots were given. `ws` answers
--- for all of them in one process, and the fan-out is what runs without it.
---@param roots string[]
---@param cb fun(commits: table[])
local function all_commits(roots, cb)
  commits_via_ws(roots, function(found)
    if found ~= nil then
      return cb(found)
    end
    all_commits_via_git(roots, cb)
  end)
end

--- `repo | sha | subject`, in three columns wide enough for every row.
---@param scopes table[]
---@return table[] items
local function render(scopes)
  local name_width, sha_width = #"all", #"workspace"
  for _, scope in ipairs(scopes) do
    if scope.kind == "commit" then
      name_width = math.max(name_width, #vim.fn.fnamemodify(scope.root, ":t"))
      sha_width = math.max(sha_width, #scope.short)
    end
  end

  local format = "%-" .. name_width .. "s | %-" .. sha_width .. "s | %s"
  local items = {}
  for _, scope in ipairs(scopes) do
    local name, sha, rest = "all", "workspace", "every repository's working diff"
    if scope.kind == "commit" then
      name, sha, rest = vim.fn.fnamemodify(scope.root, ":t"), scope.short, scope.subject
    end
    items[#items + 1] = {
      text = string.format(format, name, sha, rest),
      user_data = scope,
    }
  end
  return items
end

--- Put the scopes in the quickfix, open it along the bottom, and stand in it.
---@param items table[]
local function show(items)
  vim.fn.setqflist({}, " ", {
    title = "Review scopes: " .. state.said,
    items = items,
    -- Per list, because `nvim-pqf` sets the global one, and a row naming no file comes
    -- back from it as a bare `||` with the columns gone.
    quickfixtextfunc = function(info)
      local got = vim.fn.getqflist({ id = info.id, items = 1 }).items
      local lines = {}
      for index = info.start_idx, info.end_idx do
        lines[#lines + 1] = got[index] and got[index].text or ""
      end
      return lines
    end,
  })
  state.id = vim.fn.getqflist({ id = 0 }).id
  pcall(vim.cmd, "botright copen 10")
  local win = qf_winid()
  if win then
    pcall(vim.api.nvim_set_current_win, win)
  end
end

--- Open one scope, replacing whatever session is open.
---@param scope table
local function open(scope)
  local api = require("harness.api")

  if scope.kind == "all" then
    state.said = "workspace"
    api.review_pick()
    return
  end

  local label = vim.fn.fnamemodify(scope.root, ":t")
  state.said = label .. " " .. scope.short

  require("harness.review").open_revision(scope.root, {
    sha = scope.sha,
    parent = scope.parent,
    short = scope.short,
  })
  vim.notify(string.format("Harness: %s %s %s", label, scope.short, scope.subject), vim.log.levels.INFO)
end

--- Open the scope on the cursor's row. False when the quickfix holds something else, so
--- a caller can fall back to opening a file.
---@return boolean handled
function M.activate()
  if not M.is_shown() then
    return false
  end
  local win = qf_winid()
  if win == nil then
    return false
  end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local item = vim.fn.getqflist({ id = state.id, items = 1 }).items[row]
  if item == nil or item.user_data == nil then
    return false
  end
  open(item.user_data)
  return true
end

--- Step to the next or previous scope and open it.
---@param delta integer
---@return boolean handled
function M.step(delta)
  if not M.is_shown() then
    return false
  end
  local win = qf_winid()
  if win == nil then
    return false
  end
  local size = vim.fn.getqflist({ id = state.id, size = 1 }).size
  local at = vim.api.nvim_win_get_cursor(win)[1]
  local row = math.min(math.max(at + delta, 1), size)
  -- A step off either end moves nowhere, and re-opening the scope already open would
  -- tear down the session and rebuild it for no change.
  if row == at then
    return true
  end
  pcall(vim.api.nvim_win_set_cursor, win, { row, 0 })
  return M.activate()
end

--- Build the scope list from the review's repositories and show it.
function M.open()
  scope_roots(function(roots)
    if #roots == 0 then
      vim.notify("Harness: no git repository under " .. require("utils.gitrepo").workspace(), vim.log.levels.WARN)
      return
    end
    all_commits(roots, function(found)
      local scopes = { { kind = "all" } }
      for _, commit in ipairs(found) do
        scopes[#scopes + 1] = commit
      end
      show(render(scopes))
    end)
  end)
end

return M
