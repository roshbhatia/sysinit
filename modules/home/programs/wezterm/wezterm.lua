local wezterm = require("wezterm")

-- Bootstrap package path before loading modules
local home_dir = os.getenv("HOME") or (os.getenv("USER") and "/Users/" .. os.getenv("USER"))
package.path = package.path
  .. ";"
  .. home_dir
  .. "/.config/wezterm/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.config/wezterm/lua/?/init.lua"

local config = wezterm.config_builder()

-- Load custom color schemes
local color_schemes = {}
local colors_dir = home_dir .. "/.config/wezterm/colors"
local ok, files = pcall(wezterm.read_dir, colors_dir)
if ok then
  for _, path in ipairs(files) do
    local name = path:match("([^/]+)%.lua$")
    if name then
      local success, scheme = pcall(require, "colors." .. name)
      if success then
        color_schemes[name] = scheme
      end
    end
  end
end
config.color_schemes = color_schemes

require("sysinit.pkg.core").setup(config)
require("sysinit.pkg.sessions").setup(config)
require("sysinit.pkg.keybindings").setup(config)
require("sysinit.pkg.ui").setup(config)

return config
