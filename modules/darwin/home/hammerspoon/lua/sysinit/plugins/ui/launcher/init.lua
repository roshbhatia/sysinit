local M = {}
local json = require("sysinit.pkg.utils.json_loader")

function M.setup()
  local loaded = rawget(_G, "spoon") or {}
  local palette = loaded.CommandPalette or hs.loadSpoon("CommandPalette")
  if not palette then
    hs.alert.show("CommandPalette could not load; check the Hammerspoon console")
    return
  end
  local config = json.load_json_file(json.get_config_path("launcher_config.json")) or {}
  config.theme = json.load_json_file(json.get_config_path("theme_config.json"))
  config.screenshots = require("sysinit.plugins.ui.screenshots")
  palette:stop():configure(config):bindHotkeys({ toggle = { { "cmd" }, "space" } }):start()
end

return M
