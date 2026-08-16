local wezterm = require("wezterm")

local M = {}

local OPTIONAL = { "events", "keybindings", "mux", "ui" }

local function report(failures)
  for _, f in ipairs(failures) do
    wezterm.log_error("sysinit: " .. f.module .. ".setup failed: " .. tostring(f.err))
  end

  local summary = #failures .. " module(s) failed: "
  for i, f in ipairs(failures) do
    summary = summary .. (i > 1 and ", " or "") .. f.module
  end

  -- `gui-startup` never fires for a GUI that connects to the mux instead of
  -- starting its own, so the toast rides the first status update instead.
  local toasted = false
  pcall(function()
    wezterm.on("update-status", function(window)
      if toasted then
        return
      end
      toasted = true
      window:toast_notification("sysinit config degraded", summary, nil, 10000)
    end)
  end)
end

function M.build()
  local config = {}
  if wezterm.config_builder then
    config = wezterm.config_builder()
  end

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
