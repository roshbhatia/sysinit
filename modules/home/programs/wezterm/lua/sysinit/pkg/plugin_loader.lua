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

  -- Add plugin dirs to package.path so internal requires resolve
  package.path = nix_path .. "/plugin/?.lua;"
    .. nix_path .. "/plugin/?/init.lua;"
    .. package.path

  local ok, result = pcall(dofile, nix_path .. "/plugin/init.lua")
  if not ok then
    wezterm.log_warn("Failed to load " .. name .. ": " .. tostring(result))
  end
  return ok, result
end

return M
