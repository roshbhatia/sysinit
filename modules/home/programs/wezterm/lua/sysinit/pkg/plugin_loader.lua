-- Plugin loader: loads wezterm plugins from Nix store paths or falls back to runtime fetch.
-- Nix pre-fetches plugins as git repos so wezterm.plugin.require("file://...") works.
local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local config_data = utils.load_json_file(utils.get_config_path("config.json"))
local plugins_config = config_data and config_data.plugins or {}

function M.load(name, fallback_url)
  local nix_path = plugins_config[name]
  if nix_path then
    local ok, result = pcall(wezterm.plugin.require, "file://" .. nix_path)
    if ok then
      return true, result
    else
      wezterm.log_warn("Failed to load " .. name .. " from Nix store: " .. tostring(result))
    end
  end

  -- Fall back to runtime git clone (works on macOS)
  return pcall(wezterm.plugin.require, fallback_url)
end

return M
