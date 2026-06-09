-- Plugin loader: loads wezterm plugins from Nix store paths via plain Lua.
-- Bypasses wezterm.plugin.require entirely (broken on NixOS due to
-- gitconfig insteadOf SSH rewrite + libgit2 lacking SSH support).
local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

-- Track loaded plugins for wezterm.plugin.list() compatibility
local loaded_plugins = {}

-- Monkey-patch wezterm.plugin.list to include our manually loaded plugins.
-- Some plugins (tabline.wez) call this at module scope to find their own directory.
local original_list = wezterm.plugin.list
wezterm.plugin.list = function()
  local real = original_list()
  for _, entry in ipairs(loaded_plugins) do
    table.insert(real, entry)
  end
  return real
end

-- Load a Lua chunk from `path` under environment `env`, returning the compiled
-- function (or nil if the file is absent). Uses io.open + load rather than
-- loadfile so the per-plugin environment is applied portably.
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

  -- Register in plugin list before loading (some plugins read list() at load time)
  table.insert(loaded_plugins, {
    url = "file://" .. nix_path,
    component = name,
    plugin_dir = nix_path,
  })

  -- Add plugin dirs to package.path so any fall-through requires (and other
  -- plugins' cross-plugin lookups, e.g. ribbon -> warp.*) still resolve.
  package.path = nix_path .. "/plugin/?.lua;"
    .. nix_path .. "/plugin/?/init.lua;"
    .. package.path

  -- Per-plugin module isolation. Several of these plugins require generic bare
  -- module names ("config", "state", "data", ...) that would all collide in the
  -- single global package.loaded cache and clobber each other — e.g. agent-deck
  -- and workspace-manager both `require("config")` at runtime, and the global
  -- cache can only hold one. We give each plugin a private module cache plus a
  -- scoped require, propagated through the chunk environment so it is also used
  -- by the plugin's runtime closures. Modules that don't exist under this
  -- plugin's dir (wezterm, sysinit.*, another plugin's namespaced modules) fall
  -- back to the real global require.
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
        plugin_cache[modname] = true -- cycle guard before running the chunk
        local result = chunk(modname, path)
        if result == nil then
          result = true
        end
        plugin_cache[modname] = result
        return result
      end
    end
    -- Not part of this plugin — defer to the global loader.
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
