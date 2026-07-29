-- Config entrypoint. Lives in a .lua file rather than inline in default.nix's
-- `extraConfig` so `checks.wezterm-lua-parses` actually sees it: the check globs
-- *.lua, and a Nix string literal is invisible to it.
--
-- default.nix keeps only the package.path lines inline, because those are what
-- make this module resolvable in the first place.
local wezterm = require("wezterm")

local M = {}

function M.build()
  local config = {}
  if wezterm.config_builder then
    config = wezterm.config_builder()
  end

  require("sysinit.pkg.core").setup(config)
  require("sysinit.pkg.events").setup(config)
  require("sysinit.pkg.keybindings").setup(config)
  require("sysinit.pkg.ui").setup(config)

  return config
end

return M
