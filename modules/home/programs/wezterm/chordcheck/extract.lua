local stub_path, lua_root = ...
assert(stub_path and lua_root, "usage: extract.lua <stub.lua> <lua-root>")

package.preload["wezterm"] = function()
  return dofile(stub_path)
end
package.path = lua_root .. "/?.lua;" .. lua_root .. "/?/init.lua;" .. package.path

local config = {}
require("sysinit.pkg.keybindings").setup(config)

if not config.keys or #config.keys == 0 then
  io.stderr:write("extract: keybindings.setup bound no keys\n")
  os.exit(1)
end

local MOD = { SUPER = "cmd", CTRL = "ctrl", ALT = "alt", SHIFT = "shift" }
local ORDER = { "cmd", "ctrl", "alt", "shift" }

local KEY = {
  Tab = "tab",
  Escape = "escape",
  Enter = "enter",
  UpArrow = "up",
  DownArrow = "down",
  LeftArrow = "left",
  RightArrow = "right",
}

local function canonical(mods, key)
  local present = {}
  for token in tostring(mods or ""):gmatch("[^|]+") do
    local name = MOD[token]
    if name then
      present[name] = true
    end
  end

  local parts = {}
  for _, name in ipairs(ORDER) do
    if present[name] then
      table.insert(parts, name)
    end
  end

  local k = tostring(key):gsub("^phys:", "")
  k = KEY[k] or k:lower()
  table.insert(parts, k)
  return table.concat(parts, "+")
end

for _, binding in ipairs(config.keys) do
  print(canonical(binding.mods, binding.key))
end
