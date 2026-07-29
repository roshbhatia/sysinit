-- Config entrypoint. Lives in a .lua file rather than inline in default.nix's
-- `extraConfig` so `checks.wezterm-lua-parses` actually sees it: the check globs
-- *.lua, and a Nix string literal is invisible to it.
--
-- default.nix keeps only the package.path lines inline, because those are what
-- make this module resolvable in the first place.
--
-- Failure containment. Measured on this config: an error raised anywhere in the
-- module chain discards the whole config table and WezTerm falls back to its
-- built-in defaults. All 96 custom key bindings go, and because core.setup
-- writes into that same discarded table, so do default_prog, PATH, SHELL, and
-- TERM. A typo in ui.lua cost the owner their shell environment.
--
-- So: core is mandatory and unguarded, because a terminal running the wrong
-- shell with the wrong PATH is worse than a loud config error. The cosmetic
-- modules each load under pcall, so one of them failing costs only itself.
local wezterm = require("wezterm")

local M = {}

-- Modules whose failure is survivable. Order preserved: keybindings before ui,
-- as in the original entrypoint.
local OPTIONAL = { "events", "keybindings", "ui" }

-- Report a contained failure. Silent degradation is its own defect: a terminal
-- that works but is subtly wrong is harder to diagnose than one that fails
-- outright. The log always gets it; the toast is best-effort on top, since at
-- config-evaluation time there may be no GUI to toast into yet.
local function report(failures)
  for _, f in ipairs(failures) do
    wezterm.log_error("sysinit: " .. f.module .. ".setup failed: " .. tostring(f.err))
  end

  local summary = #failures .. " module(s) failed: "
  for i, f in ipairs(failures) do
    summary = summary .. (i > 1 and ", " or "") .. f.module
  end

  -- Wrapped: if the notification path itself breaks, the config must still
  -- return. The log above has already recorded the real failure.
  pcall(function()
    wezterm.on("gui-startup", function()
      wezterm.toast_notification("sysinit config degraded", summary, nil, 10000)
    end)
  end)
end

function M.build()
  local config = {}
  if wezterm.config_builder then
    config = wezterm.config_builder()
  end

  -- Not wrapped, on purpose. See the header.
  require("sysinit.pkg.core").setup(config)

  local failures = {}
  for _, name in ipairs(OPTIONAL) do
    local ok, err = pcall(function()
      require("sysinit.pkg." .. name).setup(config)
    end)
    if not ok then
      table.insert(failures, { module = name, err = err })
    end
  end

  if #failures > 0 then
    report(failures)
  end

  return config
end

return M
