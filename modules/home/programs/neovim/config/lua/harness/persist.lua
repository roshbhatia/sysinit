local M = {}

local STATE_DIR = vim.fn.stdpath("state") .. "/harness"

-- -@param name string  filename without extension (e.g.
function M.path(name)
  return STATE_DIR .. "/" .. name .. ".json"
end

-- -@param path string -@return table|nil
function M.load(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local raw = fd:read("*a")
  fd:close()
  if not raw or raw == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == "table" then
    return data
  end
  return nil
end

-- -@param path string -@param data table
function M.save(path, data)
  vim.fn.mkdir(STATE_DIR, "p")
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then
    return
  end
  local tmp = path .. ".tmp"
  local fd = io.open(tmp, "w")
  if not fd then
    return
  end
  fd:write(encoded)
  fd:close()
  pcall(vim.uv.fs_rename, tmp, path)
end

return M
