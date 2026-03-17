-- Plugin loader: loads wezterm plugins from Nix store git clones via file:// URLs.
local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

function M.load(name)
  local nix_path = plugins_config[name]
  if not nix_path then
    wezterm.log_warn("No Nix store path for plugin: " .. name)
    return false, nil
  end

  local ok, result = pcall(wezterm.plugin.require, "file://" .. nix_path)
  if not ok then
    wezterm.log_warn("Failed to load " .. name .. ": " .. tostring(result))
  end
  return ok, result
end

return M
