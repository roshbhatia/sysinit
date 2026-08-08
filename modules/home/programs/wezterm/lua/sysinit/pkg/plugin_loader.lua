local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

local loaded_plugins = {}

local original_list = wezterm.plugin.list
wezterm.plugin.list = function()
  local real = original_list()
  for _, entry in ipairs(loaded_plugins) do
    table.insert(real, entry)
  end
  return real
end

local function load_chunk(path, env)
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  local content = fh:read("*a")
  fh:close()
  local chunk, err = load(content, "@" .. path, "t", env)
  if not chunk then
    error(err)
  end
  return chunk
end

function M.load(name)
  local nix_path = plugins_config[name]
  if not nix_path then
    wezterm.log_warn("No path configured for plugin: " .. name)
    return false, nil
  end

  table.insert(loaded_plugins, {
    url = "file://" .. nix_path,
    component = name,
    plugin_dir = nix_path,
  })

  package.path = nix_path .. "/plugin/?.lua;"
    .. nix_path .. "/plugin/?/init.lua;"
    .. package.path

  local plugin_cache = {}
  local plugin_base = nix_path .. "/plugin/"
  local env

  local function scoped_require(modname)
    if plugin_cache[modname] ~= nil then
      return plugin_cache[modname]
    end
    local rel = modname:gsub("%.", "/")
    for _, path in ipairs({ plugin_base .. rel .. ".lua", plugin_base .. rel .. "/init.lua" }) do
      local chunk = load_chunk(path, env)
      if chunk then
        plugin_cache[modname] = true
        local result = chunk(modname, path)
        if result == nil then
          result = true
        end
        plugin_cache[modname] = result
        return result
      end
    end
    return require(modname)
  end

  env = setmetatable({ require = scoped_require }, { __index = _G })

  local init_chunk
  local lerr_ok, lerr = pcall(function()
    init_chunk = load_chunk(plugin_base .. "init.lua", env)
  end)
  if not lerr_ok then
    wezterm.log_warn("Failed to load " .. name .. ": " .. tostring(lerr))
    return false, nil
  end
  if not init_chunk then
    wezterm.log_warn("Failed to load " .. name .. ": missing plugin/init.lua")
    return false, nil
  end

  local ok, result = pcall(init_chunk)
  if not ok then
    wezterm.log_warn("Failed to load " .. name .. ": " .. tostring(result))
  end
  return ok, result
end

return M
