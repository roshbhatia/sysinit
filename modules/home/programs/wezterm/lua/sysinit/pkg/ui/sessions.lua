local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

M.DEFAULT_WORKSPACE = "default"
M.DEFAULT_SLOT = 1
M.MAX_SLOT = 9
M.REFRESH_SECS = 30
M.CATALOG_VERSION = "roster.catalog/v1"

-- roster writes one roster.catalog/v1 file per source into catalog_dir. The
-- source names arrive in the order roster's own config lists them, so this
-- module never lists the directory and never decides an order of its own.
M.catalog_dir = utils.state_path("rosterCatalog", "roster/catalog")
M.sources = {}
-- `roster refresh --if-stale`, spawned from the status tick.
M.roster_refresher = ""
-- `roster open --json`, run by spawn.lua for a row whose plan is deferred.
M.roster_opener = ""
do
  local ok, cfg = pcall(utils.load_json_file, utils.get_config_path("config.json"))
  if ok and type(cfg) == "table" then
    if type(cfg.scripts) == "table" then
      M.roster_refresher = cfg.scripts.roster_refresh or ""
      M.roster_opener = cfg.scripts.roster_open or ""
    end
    if type(cfg.roster) == "table" then
      if type(cfg.roster.catalog_dir) == "string" and cfg.roster.catalog_dir ~= "" then
        M.catalog_dir = cfg.roster.catalog_dir
      end
      for _, name in ipairs(cfg.roster.sources or {}) do
        if type(name) == "string" and name ~= "" then
          M.sources[#M.sources + 1] = name
        end
      end
    end
  end
end

-- Days since 1970-01-01 for a proleptic Gregorian date. os.time's table form
-- reads the local zone, and a stamp with its own offset must not.
local function days_from_civil(y, m, d)
  if m <= 2 then
    y = y - 1
  end
  local era = (y >= 0 and y or y - 399) // 400
  local yoe = y - era * 400
  local mp = (m + 9) % 12
  local doy = (153 * mp + 2) // 5 + d - 1
  local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
  return era * 146097 + doe - 719468
end

-- An RFC 3339 stamp as epoch seconds, or nil when it is not one. Fractional
-- seconds are dropped; the offset is applied.
---@param stamp string|nil e.g. 2026-09-09T03:27:12Z or 2026-09-08T20:27:12.5-07:00
---@return integer|nil
function M.parse_rfc3339(stamp)
  if type(stamp) ~= "string" then
    return nil
  end
  local y, mo, d, h, mi, s, rest = stamp:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d):(%d%d)(.*)$")
  if not y then
    return nil
  end
  local zone = rest:match("^%.%d+(.*)$") or rest
  local offset
  if zone == "Z" or zone == "z" then
    offset = 0
  else
    local sign, zh, zm = zone:match("^([+-])(%d%d):?(%d%d)$")
    if not sign then
      return nil
    end
    offset = (tonumber(zh) * 3600 + tonumber(zm) * 60) * (sign == "-" and -1 or 1)
  end
  local days = days_from_civil(tonumber(y), tonumber(mo), tonumber(d))
  return days * 86400 + tonumber(h) * 3600 + tonumber(mi) * 60 + tonumber(s) - offset
end

local duration_units = {
  ns = 1e-9,
  us = 1e-6,
  ["µs"] = 1e-6,
  ["μs"] = 1e-6,
  ms = 1e-3,
  s = 1,
  m = 60,
  h = 3600,
}

-- A Go duration string as seconds, or nil when it is not one.
---@param text string|nil e.g. 30s, 1h30m, 1.5s, 500ms
---@return number|nil
function M.parse_duration(text)
  if type(text) ~= "string" or text == "" then
    return nil
  end
  local total, pos = 0, 1
  while pos <= #text do
    local num, unit, next_pos = text:match("^(%d+%.?%d*)([^%d%.]+)()", pos)
    local scale = num and duration_units[unit]
    if not scale then
      return nil
    end
    total = total + tonumber(num) * scale
    pos = next_pos
  end
  return total
end

-- A catalog is stale once it has outlived its ttl. An unreadable stamp or ttl
-- reads as stale, never as fresh.
---@param catalog table a roster.catalog/v1 document
---@param now integer|nil epoch seconds; os.time() when nil
---@return boolean
function M.is_stale(catalog, now)
  local at = M.parse_rfc3339(catalog.generated_at)
  local ttl = M.parse_duration(catalog.ttl)
  if not at or not ttl then
    return true
  end
  return (now or os.time()) - at > ttl
end

local function missing_catalog(source, err)
  return {
    source = source,
    ok = false,
    error = err,
    display = { label = source, glyph = "", order = math.huge },
    groups = {},
    rows = {},
    stale = true,
  }
end

-- One source's catalog, read from disk. Every row gains `source` and `stale`:
-- stale when the file is, when the row's group is, or when the source marked
-- the row's own inventory stale in meta.
---@param source string
---@param now integer|nil
---@return table catalog { source, ok, error?, display, groups, rows, stale, generated_at?, ttl? }
function M.read_catalog(source, now)
  local ok, data = pcall(utils.load_json_file, M.catalog_dir .. "/" .. source .. ".json")
  if not ok then
    return missing_catalog(source, "not refreshed yet")
  end
  if type(data) ~= "table" or data.version ~= M.CATALOG_VERSION then
    return missing_catalog(source, "not a " .. M.CATALOG_VERSION .. " document")
  end
  local stale = M.is_stale(data, now)
  local groups, by_id = {}, {}
  for _, group in ipairs(data.groups or {}) do
    if type(group) == "table" and type(group.id) == "string" then
      groups[#groups + 1] = group
      by_id[group.id] = group
    end
  end
  local rows = {}
  for _, row in ipairs(data.rows or {}) do
    if type(row) == "table" and type(row.workspace) == "string" and row.workspace ~= "" then
      local group = type(row.group) == "string" and by_id[row.group] or nil
      row.source = data.source
      row.stale = stale
        or (group ~= nil and group.stale == true)
        or (type(row.meta) == "table" and row.meta.stale == true)
      rows[#rows + 1] = row
    end
  end
  return {
    source = data.source,
    ok = true,
    display = type(data.display) == "table" and data.display or {},
    groups = groups,
    rows = rows,
    stale = stale,
    generated_at = data.generated_at,
    ttl = data.ttl,
  }
end

local catalog_cache = { at = -1, list = {} }

-- Every configured source's catalog, in config order, re-read at most every
-- five seconds. The status tick and the tree both call this.
function M.catalogs()
  local now = os.time()
  if now - catalog_cache.at >= 5 then
    local list = {}
    for _, source in ipairs(M.sources) do
      list[#list + 1] = M.read_catalog(source, now)
    end
    catalog_cache = { at = now, list = list }
  end
  return catalog_cache.list
end

-- The catalog row a workspace name belongs to, or nil when no source lists it.
---@param workspace string
---@return table|nil row
function M.row_for(workspace)
  for _, catalog in ipairs(M.catalogs()) do
    for _, row in ipairs(catalog.rows) do
      if row.workspace == workspace then
        return row
      end
    end
  end
  return nil
end

local refresh_at = -1

-- Spawns `roster refresh --if-stale` in the background, at most once every
-- REFRESH_SECS. roster skips a source whose file is inside its ttl and exits
-- at once when another refresh is running, so a tick never stacks probes.
function M.refresh_catalogs()
  local now = os.time()
  if now - refresh_at < M.REFRESH_SECS then
    return
  end
  refresh_at = now
  if M.roster_refresher == "" then
    return
  end
  pcall(function()
    wezterm.background_child_process({ M.roster_refresher })
  end)
end

function M.active_names()
  local seen, names = {}, {}
  pcall(function()
    for _, win in ipairs(wezterm.mux.all_windows()) do
      local n = win:get_workspace()
      if n and n ~= "" and not seen[n] then
        seen[n] = true
        names[#names + 1] = n
      end
    end
  end)
  return names
end

local function compute_slots()
  local prev = wezterm.GLOBAL.workspace_slots
  if type(prev) ~= "table" then
    prev = {}
  end

  local names = M.active_names()
  if #names == 0 then
    return prev
  end

  local present = {}
  for _, n in ipairs(names) do
    present[n] = true
  end

  local slots, taken = {}, {}
  taken[M.DEFAULT_SLOT] = true
  for name, slot in pairs(prev) do
    if present[name] and name ~= M.DEFAULT_WORKSPACE and type(slot) == "number" and not taken[slot] then
      slots[name] = slot
      taken[slot] = true
    end
  end

  local fresh = {}
  for _, n in ipairs(names) do
    if n ~= M.DEFAULT_WORKSPACE and not slots[n] then
      fresh[#fresh + 1] = n
    end
  end
  table.sort(fresh)
  local probe = 1
  for _, name in ipairs(fresh) do
    while probe <= M.MAX_SLOT and taken[probe] do
      probe = probe + 1
    end
    if probe > M.MAX_SLOT then
      break
    end
    slots[name] = probe
    taken[probe] = true
  end

  slots[M.DEFAULT_WORKSPACE] = M.DEFAULT_SLOT

  local changed = false
  for name, slot in pairs(slots) do
    if prev[name] ~= slot then
      changed = true
      break
    end
  end
  if not changed then
    for name in pairs(prev) do
      if slots[name] == nil then
        changed = true
        break
      end
    end
  end
  if changed then
    wezterm.GLOBAL.workspace_slots = slots
  end
  return slots
end

local slots_cache = { at = -1, slots = {} }

function M.slots()
  local now = os.time()
  if now ~= slots_cache.at then
    slots_cache = { at = now, slots = compute_slots() }
  end
  return slots_cache.slots
end

local touch_throttle = {}

function M.touch(name)
  if not name or name == "" then
    return
  end
  local now = os.time()
  if touch_throttle[name] and now - touch_throttle[name] < 5 then
    return
  end
  touch_throttle[name] = now
  local t = wezterm.GLOBAL.workspace_last_active or {}
  t[name] = now
  wezterm.GLOBAL.workspace_last_active = t
end

function M.last_active(name)
  local t = wezterm.GLOBAL.workspace_last_active
  return type(t) == "table" and t[name] or nil
end

return M
