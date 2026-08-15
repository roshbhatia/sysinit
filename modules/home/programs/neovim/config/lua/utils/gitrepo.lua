local M = {}

local TOOL = "utils"

---@class Change
---@field path string
---@field status string  git's own two-character porcelain code

---@class Group
---@field root string
---@field files Change[]

---@class Report
---@field workspace string
---@field roots string[]
---@field groups Group[]

---@type Report|nil
local last = nil

---@return string
local function here()
  return vim.fs.normalize(vim.uv.cwd() or ".")
end

---@param dir string|nil
---@return string|nil
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

---@param buf? number
---@return string|nil
function M.buffer_root(buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if file == "" or not vim.uv.fs_stat(file) then
    return nil
  end
  return toplevel(vim.fn.fnamemodify(file, ":h"))
end

---@return string|nil
function M.cwd_root()
  return toplevel(here())
end

---@param report Report
---@return Report
local function normalized(report)
  local roots = {}
  for _, root in ipairs(report.roots or {}) do
    roots[#roots + 1] = vim.fs.normalize(root)
  end
  local groups = {}
  for _, group in ipairs(report.groups or {}) do
    local files = {}
    for _, file in ipairs(group.files or {}) do
      files[#files + 1] = { path = vim.fs.normalize(file.path), status = file.status or "  " }
    end
    groups[#groups + 1] = { root = vim.fs.normalize(group.root), files = files }
  end
  table.sort(groups, function(a, b)
    if #a.files ~= #b.files then
      return #a.files > #b.files
    end
    return a.root < b.root
  end)
  return { workspace = vim.fs.normalize(report.workspace or here()), roots = roots, groups = groups }
end

-- One call answers what the workspace is, which repositories are under it, and
-- what changed in each. Neovim owns no second rule for any of the three, so a
-- folder of repositories and a single repository cannot read differently here.
---@param cb fun(report: Report)
function M.report(cb)
  if vim.fn.executable(TOOL) ~= 1 then
    vim.notify("Workspace: " .. TOOL .. " is not on PATH", vim.log.levels.ERROR)
    return cb({ workspace = here(), roots = {}, groups = {} })
  end
  vim.system({ TOOL, "workspace", "changes", "--json", here() }, { text = true }, function(result)
    local found = nil
    if result.code == 0 then
      local ok, decoded = pcall(vim.json.decode, result.stdout or "")
      if ok and type(decoded) == "table" then
        found = normalized(decoded)
      end
    end
    vim.schedule(function()
      if found == nil then
        vim.notify("Workspace: " .. vim.trim(result.stderr or "the scan failed"), vim.log.levels.ERROR)
        found = { workspace = here(), roots = {}, groups = {} }
      end
      last = found
      cb(found)
    end)
  end)
end

-- What the last scan saw, for a caller that must answer without waiting. It is
-- nil until a scan has run, and never a second scan of its own.
---@return Report|nil
function M.cached()
  return last
end

---@return string
function M.workspace()
  if last then
    return last.workspace
  end
  return M.cwd_root() or here()
end

-- Roots move when a repository is cloned or removed, so the last answer stands
-- until the directory changes. Changes move on every write, so they are re-read.
---@param cb fun(roots: string[])
function M.workspace_roots(cb)
  if last then
    return cb(last.roots)
  end
  M.report(function(report)
    cb(report.roots)
  end)
end

---@param cb fun(groups: Group[], roots: string[])
function M.workspace_changes(cb)
  M.report(function(report)
    cb(report.groups, report.roots)
  end)
end

---@param path string
---@param roots string[]
---@return string|nil
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

---@param cb fun(root: string)
---@param opts? { ask?: boolean }
function M.resolve(cb, opts)
  local ask = (opts or {}).ask == true
  M.workspace_roots(function(roots)
    if #roots == 0 then
      vim.notify("No git repository under " .. vim.fn.fnamemodify(M.workspace(), ":~"), vim.log.levels.WARN)
      return
    end
    if #roots == 1 then
      return cb(roots[1])
    end

    local buffer = not ask and M.buffer_root() or nil
    if buffer then
      return cb(M.owning_root(buffer, roots) or buffer)
    end

    vim.ui.select(roots, {
      prompt = "Select git repo",
      format_item = function(root)
        return vim.fn.fnamemodify(root, ":~:.")
      end,
    }, function(choice)
      if choice then
        cb(choice)
      end
    end)
  end)
end

---@return { source: string, workspace: string, roots: string[], agent: boolean }
function M.status()
  return {
    source = last and (TOOL .. " workspace") or "none",
    workspace = M.workspace(),
    roots = last and last.roots or {},
    agent = vim.fn.executable(TOOL) == 1,
  }
end

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("gitrepo_cache", { clear = true }),
  callback = function()
    last = nil
  end,
})

return M
