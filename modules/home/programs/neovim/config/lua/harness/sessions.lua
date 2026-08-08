local M = {}

local TIMEOUT_MS = 3000

---@param argv string[]
---@return { ok: boolean, stdout: string, stderr: string }
local function run_with_timeout(argv)
  local ok_call, sys = pcall(vim.system, argv, { text = true })
  if not ok_call or not sys then
    return { ok = false, stdout = "", stderr = "spawn failed" }
  end
  local obj = sys:wait(TIMEOUT_MS)
  if not obj then
    return { ok = false, stdout = "", stderr = "timed out after " .. TIMEOUT_MS .. "ms" }
  end
  return {
    ok = (obj.code == 0),
    stdout = obj.stdout or "",
    stderr = obj.stderr or "",
  }
end

local function decode_json(raw)
  if not raw or raw == "" then return nil end
  local ok, data = pcall(vim.json.decode, raw)
  if not ok then return nil end
  return data
end

---@class harness.SessionListResult
---@field ok     boolean
---@field items? { value: string, label: string }[]
---@field error? string

local LISTERS = {}

function LISTERS.crush()
  local res = run_with_timeout({ "crush", "session", "list", "--json" })
  if not res.ok then
    local msg = res.stderr ~= "" and res.stderr or res.stdout
    msg = vim.trim(msg):gsub("%s+", " "):sub(1, 200)
    return { ok = false, error = "crush session list failed: " .. (msg ~= "" and msg or "exit nonzero") }
  end
  local data = decode_json(res.stdout)
  if type(data) ~= "table" then
    return { ok = false, error = "crush session list returned non-JSON output" }
  end
  local items = {}
  for _, s in ipairs(data) do
    local title = s.title or s.name or s.id or "?"
    table.insert(items, {
      value = s.id,
      label = string.format("%s  (%s)", title, tostring(s.id):sub(1, 8)),
    })
  end
  return { ok = true, items = items }
end

function LISTERS.goose()
  local res = run_with_timeout({ "goose", "session", "list", "-f", "json" })
  if not res.ok then
    local msg = res.stderr ~= "" and res.stderr or res.stdout
    msg = vim.trim(msg):gsub("%s+", " "):sub(1, 200)
    return { ok = false, error = "goose session list failed: " .. (msg ~= "" and msg or "exit nonzero") }
  end
  local data = decode_json(res.stdout)
  if type(data) ~= "table" then
    return { ok = false, error = "goose session list returned non-JSON output" }
  end
  local items = {}
  for _, s in ipairs(data) do
    local name = s.name or s.id or "?"
    local desc = s.description or s.summary or ""
    table.insert(items, {
      value = name,
      label = desc ~= "" and (name .. " — " .. desc) or name,
    })
  end
  return { ok = true, items = items }
end

---@param source string
---@param on_select fun(value: string|nil)
function M.list(source, on_select)
  local lister = LISTERS[source]
  if not lister then
    vim.notify("Harness: no session picker for " .. source, vim.log.levels.WARN)
    on_select(nil)
    return
  end

  local result = lister()
  if not result.ok then
    vim.notify("Harness: " .. (result.error or "unknown error"), vim.log.levels.ERROR)
    on_select(nil)
    return
  end

  if not result.items or #result.items == 0 then
    vim.notify("Harness: no " .. source .. " sessions in this project", vim.log.levels.INFO)
    on_select(nil)
    return
  end

  local ok_snacks, snacks = pcall(require, "snacks")
  if not (ok_snacks and snacks.picker) then
    vim.ui.select(result.items, {
      prompt = "Resume " .. source .. " session:",
      format_item = function(item) return item.label end,
    }, function(item)
      on_select(item and item.value or nil)
    end)
    return
  end

  snacks.picker.pick({
    source = "harness_sessions_" .. source,
    items = result.items,
    format = function(item) return { { item.label, "Normal" } } end,
    title = "Resume — " .. source,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      on_select(item and item.value or nil)
    end,
  })
end

---@param source string
---@return harness.SessionListResult
function M._probe(source)
  local lister = LISTERS[source]
  if not lister then
    return { ok = false, error = "no lister" }
  end
  return lister()
end

return M
