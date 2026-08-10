local wezterm = require("wezterm")
local M = {}

function M.is_linux()
  return wezterm.target_triple:find("linux") ~= nil
end

function M.is_darwin()
  return wezterm.target_triple:find("darwin") ~= nil
end

function M.get_username()
  return os.getenv("USER") or ""
end

function M.get_home_dir()
  local home = os.getenv("HOME")
  if home then
    return home
  end
  return "/Users/" .. M.get_username()
end

function M.get_nix_user_bin()
  return "/etc/profiles/per-user/" .. M.get_username() .. "/bin"
end

function M.get_nix_binary(name)
  return M.get_nix_user_bin() .. "/" .. name
end

function M.get_process_name(pane)
  local proc = pane:get_foreground_process_name()
  if not proc then
    return nil
  end
  return proc:match("([^/\\]+)$")
end

function M.load_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open file: " .. filepath)
  end

  local content = file:read("*all")
  file:close()

  local success, data = pcall(wezterm.json_parse, content)

  if not success then
    error("Failed to parse JSON from: " .. filepath .. "\nError: " .. tostring(data))
  end

  return data
end

function M.get_config_path(filename)
  return M.get_home_dir() .. "/.config/wezterm/" .. filename
end

-- The paths manifest, read once per config load.
local paths_cache = nil

-- The single fallback of the wezterm tree. It locates the manifest, and it is
-- the root every key below falls back under when the manifest is absent.
local function state_root()
  -- sysinit:documented-default
  return os.getenv("XDG_STATE_HOME") or (M.get_home_dir() .. "/.local/state")
end

local function paths_manifest()
  if paths_cache ~= nil then
    return paths_cache
  end
  local ok, data = pcall(M.load_json_file, state_root() .. "/sysinit/paths.json")
  paths_cache = (ok and type(data) == "table" and type(data.paths) == "table") and data.paths or {}
  return paths_cache
end

-- Resolve one state path by key.
function M.state_path(key, fallback_suffix)
  local value = paths_manifest()[key]
  if type(value) == "string" and value ~= "" then
    return (value:gsub("/$", ""))
  end
  return state_root() .. "/" .. fallback_suffix
end

return M
