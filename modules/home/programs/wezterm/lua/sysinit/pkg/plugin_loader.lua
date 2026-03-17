-- Plugin loader: loads wezterm plugins from Nix store paths or falls back to runtime fetch.
-- Nix store paths aren't git repos, so we can't use wezterm.plugin.require with file://.
-- Instead, we add the plugin's directory to package.path and dofile its init.lua.
local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

function M.load(name, fallback_url)
  local nix_path = plugins_config[name]
  if nix_path then
    -- Add plugin dirs to package.path permanently so lazy requires work during setup()
    package.path = nix_path .. "/plugin/?.lua;"
      .. nix_path .. "/plugin/?/init.lua;"
      .. nix_path .. "/?.lua;"
      .. nix_path .. "/?/init.lua;"
      .. package.path

    local ok, result = pcall(dofile, nix_path .. "/plugin/init.lua")
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
