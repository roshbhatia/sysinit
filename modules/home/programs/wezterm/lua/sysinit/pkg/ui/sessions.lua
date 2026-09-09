local wezterm = require("wezterm")

local M = {}
M.DEFAULT_WORKSPACE = "default"
M.DEFAULT_SLOT = 1
M.MAX_SLOT = 9

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
