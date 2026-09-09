local M = {}

-- Where gate's edit-event provider writes. There is no query verb: the provider
-- and this module derive the same paths from the paths manifest's `agentEdits`
-- entry and go-utils' paths.Keyed, so the bytes here must not drift from
-- `<dir>/<base>-<first 16 hex of sha256(root)>`.

---@return string
local function state_home()
  local declared = vim.env.XDG_STATE_HOME
  if declared and declared ~= "" then
    return declared
  end
  return vim.fs.joinpath(vim.env.HOME or vim.uv.os_homedir(), ".local", "state")
end

---@type table<string, string>|nil
local manifest = nil

---The paths manifest, read once. An absent or unreadable manifest is an empty
---table, so every key falls to its default, which is how a box with no manifest
---and the Go side agree.
---@return table<string, string>
local function paths()
  if manifest then
    return manifest
  end
  manifest = {}
  local file = vim.fs.joinpath(state_home(), "sysinit", "paths.json")
  local handle = io.open(file, "r")
  if not handle then
    return manifest
  end
  local body = handle:read("*a")
  handle:close()
  local ok, doc = pcall(vim.json.decode, body)
  if ok and type(doc) == "table" and type(doc.paths) == "table" then
    for key, value in pairs(doc.paths) do
      if type(value) == "string" and value:sub(1, 1) == "/" then
        manifest[key] = value
      end
    end
  end
  return manifest
end

---@return string
function M.edits_dir()
  return paths().agentEdits or vim.fs.joinpath(state_home(), "agents", "edits")
end

---The workspace boundary, the rule go-utils' workspace.Root applies:
---`$SYSINIT_WORKSPACE` when the cwd sits inside it, then the git top level,
---then the cwd itself.
---@param dir? string
---@return string
function M.workspace(dir)
  dir = (dir or vim.uv.cwd() or "."):gsub("/+$", "")
  local declared = (vim.env.SYSINIT_WORKSPACE or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+$", "")
  if declared ~= "" then
    local stat = vim.uv.fs_stat(declared)
    if stat and stat.type == "directory" and (dir == declared or dir:sub(1, #declared + 1) == declared .. "/") then
      return declared
    end
  end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
  return dir
end

---@param dir string
---@param root string
---@return string
function M.keyed(dir, root)
  return string.format("%s/%s-%s", dir, vim.fs.basename(root), vim.fn.sha256(root):sub(1, 16))
end

---@param root? string
---@return string
function M.log_file(root)
  return M.keyed(M.edits_dir(), root or M.workspace()) .. ".jsonl"
end

---@param root? string
---@return string
function M.delta_dir(root)
  return M.keyed(M.edits_dir(), root or M.workspace()) .. ".delta"
end

---For a test that rewrites the manifest between cases.
function M.reset()
  manifest = nil
end

return M
