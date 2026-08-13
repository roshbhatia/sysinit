-- Repository discovery for a workspace that may hold several of them.
local M = {}

local SCAN_DEPTH = 5

-- Which source answered the last query, for the health report. A stall or a wrong
-- answer is then readable rather than inferred.
---@type { source: string, roots: string[], workspace: string|nil }
local last = { source = "none", roots = {}, workspace = nil }

---@type table<string, string[]>
local cache = {}

local function toplevel(dir)
  if not dir or dir == "" then
    return nil
  end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return vim.fs.normalize(out[1])
end

function M.buffer_root(buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if file == "" or not vim.uv.fs_stat(file) then
    return nil
  end
  return toplevel(vim.fn.fnamemodify(file, ":h"))
end

function M.cwd_root()
  return toplevel(vim.uv.cwd())
end

-- The subcommand, when this box has one new enough to carry it. `workspace roots`
-- exits 2 on a usage error, which is how an older binary answers, so the exit code
-- distinguishes "no repositories" from "does not know the question".
local function agent_roots(dir, cb)
  if vim.fn.executable("utils") ~= 1 then
    return cb(nil)
  end
  vim.system({ "utils", "workspace", "roots", dir }, { text = true }, function(res)
    if res.code ~= 0 then
      return cb(nil)
    end
    local roots = {}
    for line in (res.stdout or ""):gmatch("[^\n]+") do
      roots[#roots + 1] = vim.fs.normalize(line)
    end
    cb(roots)
  end)
end

-- The scan this module has always used. Kept as the fallback rather than deleted,
-- because it needs nothing this repository builds.
function M.scan(dir, cb)
  if vim.fn.executable("fd") ~= 1 then
    return cb(nil)
  end
  vim.system(
    { "fd", "-H", "-I", "-t", "d", "-t", "f", "--max-depth", tostring(SCAN_DEPTH), "^[.]git$", dir },
    { text = true },
    function(res)
      local roots, seen = {}, {}
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local root = line:match("^(.+)/%.git/?$")
        if root and not seen[root] then
          seen[root] = true
          roots[#roots + 1] = vim.fs.normalize(root)
        end
      end
      table.sort(roots)
      cb(roots)
    end
  )
end

--- The workspace boundary the environment states, or nil when it states none.
---@param dir string
---@return string|nil
local function declared_workspace(dir)
  local value = vim.env.SYSINIT_WORKSPACE
  if value == nil or value == "" then
    return nil
  end
  local root = vim.fs.normalize(vim.fn.expand(value)):gsub("/+$", "")
  local stat = vim.uv.fs_stat(root)
  if not stat or stat.type ~= "directory" then
    return nil
  end
  if dir == root or dir:sub(1, #root + 1) == root .. "/" then
    return root
  end
  return nil
end

-- Memoised per cwd: the git fallback spawns a process, and this is read on every
-- roots query, every message, and every health report.
local workspace_cache = {}

-- The workspace is the directory the roots are counted under: what the environment
-- declares, else the repository the cwd sits in, else the cwd itself.
function M.workspace()
  local cwd = vim.fs.normalize(vim.uv.cwd() or ".")
  local declared = declared_workspace(cwd)
  if declared then
    return declared
  end
  if workspace_cache[cwd] == nil then
    workspace_cache[cwd] = M.cwd_root() or cwd
  end
  return workspace_cache[cwd]
end

-- Every repository under the workspace, including one nested inside another.
function M.workspace_roots(cb)
  local dir = M.workspace()
  if cache[dir] then
    -- The source is recorded without appending, because a label built by appending
    -- to the previous one reads as "fd scan (cached) (cached)" by the third open.
    last = { source = last.source, roots = cache[dir], workspace = dir, cached = true }
    return cb(cache[dir])
  end

  local function finish(source, roots)
    roots = roots or {}
    cache[dir] = roots
    last = { source = source, roots = roots, workspace = dir }
    vim.schedule(function()
      cb(roots)
    end)
  end

  agent_roots(dir, function(roots)
    if roots then
      return finish("utils workspace", roots)
    end
    M.scan(dir, function(scanned)
      if scanned then
        return finish("fd scan", scanned)
      end
      -- Last resort: git knows one repository, which is better than none and is
      -- the answer a single-repository checkout wanted anyway.
      local root = M.cwd_root()
      finish("git rev-parse", root and { root } or {})
    end)
  end)
end

-- The repositories under the workspace that have something to review, each with its
-- changed files.
function M.workspace_changes(cb)
  M.workspace_roots(function(roots)
    if #roots == 0 then
      return cb({}, roots)
    end

    local function group_by_root(files)
      local groups, index = {}, {}
      for _, path in ipairs(files) do
        local owner = M.owning_root(path, roots)
        if owner then
          if not index[owner] then
            index[owner] = { root = owner, files = {} }
            groups[#groups + 1] = index[owner]
          end
          table.insert(index[owner].files, path)
        end
      end
      table.sort(groups, function(a, b)
        if #a.files ~= #b.files then
          return #a.files > #b.files
        end
        return a.root < b.root
      end)
      return groups
    end

    if vim.fn.executable("utils") == 1 then
      vim.system({ "utils", "workspace", "changes", M.workspace() }, { text = true }, function(res)
        if res.code == 0 then
          local files = {}
          for line in (res.stdout or ""):gmatch("[^\n]+") do
            files[#files + 1] = vim.fs.normalize(line)
          end
          return vim.schedule(function()
            cb(group_by_root(files), roots)
          end)
        end
        M._changes_via_git(roots, cb)
      end)
      return
    end

    M._changes_via_git(roots, cb)
  end)
end

-- The fallback for `workspace_changes`. Named rather than inlined so the health
-- report can say which path ran.
function M._changes_via_git(roots, cb)
  local groups, pending = {}, #roots
  for i, root in ipairs(roots) do
    vim.system({ "git", "-C", root, "status", "--porcelain", "--untracked-files=all" }, { text = true }, function(res)
      local files = {}
      if res.code == 0 then
        for line in (res.stdout or ""):gmatch("[^\n]+") do
          local rel = line:sub(4)
          local path = vim.fs.normalize(root .. "/" .. rel)
          -- A nested repository answers for itself, so its paths are dropped
          -- from the parent here the way the subcommand drops them by pathspec.
          if M.owning_root(path, roots) == root then
            files[#files + 1] = path
          end
        end
      end
      if #files > 0 then
        groups[i] = { root = root, files = files }
      end
      pending = pending - 1
      if pending == 0 then
        -- Indexed by root position, so a clean repository leaves a hole and
        -- `ipairs` would stop at the first one. Walked by index instead.
        local kept = {}
        for index = 1, #roots do
          if groups[index] then
            kept[#kept + 1] = groups[index]
          end
        end
        table.sort(kept, function(a, b)
          if #a.files ~= #b.files then
            return #a.files > #b.files
          end
          return a.root < b.root
        end)
        vim.schedule(function()
          cb(kept, roots)
        end)
      end
    end)
  end
end

-- The repository a path belongs to: the longest root that prefixes it, which is
-- what makes a nested repository win over the parent it sits in.
function M.owning_root(path, roots)
  local best = nil
  for _, root in ipairs(roots) do
    if path == root or path:sub(1, #root + 1) == root .. "/" then
      if not best or #root > #best then
        best = root
      end
    end
  end
  return best
end

-- Resolve one repo root for a command that needs one, preferring the repo the current
-- buffer lives in so a workspace holding several repos does not prompt.
function M.resolve(cb)
  M.workspace_roots(function(roots)
    if #roots == 0 then
      vim.notify("No git repository under " .. vim.fn.fnamemodify(M.workspace(), ":~"), vim.log.levels.WARN)
      return
    end
    if #roots == 1 then
      return cb(roots[1])
    end

    local buffer = M.buffer_root()
    if buffer then
      local owner = M.owning_root(buffer, roots) or buffer
      return cb(owner)
    end

    vim.ui.select(roots, {
      prompt = "Select git repo",
      format_item = function(r)
        return vim.fn.fnamemodify(r, ":~:.")
      end,
    }, function(choice)
      if choice then
        cb(choice)
      end
    end)
  end)
end

-- What answered last, for `:checkhealth`.
function M.status()
  return {
    source = last.source,
    workspace = last.workspace or M.workspace(),
    roots = last.roots,
    agent = vim.fn.executable("utils") == 1,
    fd = vim.fn.executable("fd") == 1,
  }
end

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("gitrepo_cache", { clear = true }),
  callback = function()
    cache = {}
  end,
})

return M
