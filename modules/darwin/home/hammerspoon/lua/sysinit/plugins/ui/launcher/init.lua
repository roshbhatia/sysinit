local M = {}
local json = require("sysinit.pkg.utils.json_loader")

function M.setup()
  local palette = hs.loadSpoon("CommandPalette")
  local config = json.load_json_file(json.get_config_path("launcher_config.json")) or {}
  config.theme = json.load_json_file(json.get_config_path("theme_config.json"))
  config.screenshots = require("sysinit.plugins.ui.screenshots")
  palette:stop():configure(config):bindHotkeys({ toggle = { { "cmd" }, "space" } }):start()
end

return M
