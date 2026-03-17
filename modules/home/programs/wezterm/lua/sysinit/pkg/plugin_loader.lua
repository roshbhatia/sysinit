-- Plugin loader: loads wezterm plugins from Nix store paths or falls back to runtime fetch.
-- Nix store paths aren't git repos, so we can't use wezterm.plugin.require with file://.
-- Instead, we add the plugin's directory to package.path and require its init.lua directly.
local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

function M.load(name, fallback_url)
  local nix_path = plugins_config[name]
  if nix_path then
    -- Add the plugin's directories to package.path so internal requires work
    local old_path = package.path
    package.path = nix_path .. "/plugin/?.lua;"
      .. nix_path .. "/plugin/?/init.lua;"
      .. nix_path .. "/?.lua;"
      .. nix_path .. "/?/init.lua;"
      .. package.path

    local ok, result = pcall(dofile, nix_path .. "/plugin/init.lua")

    -- Restore package.path to avoid pollution
    package.path = old_path

    if ok then
      return true, result
    else
      wezterm.log_warn("Failed to load " .. name .. " from Nix store: " .. tostring(result))
    end
  end

  -- Fall back to runtime git clone
  return pcall(wezterm.plugin.require, fallback_url)
end

return M
