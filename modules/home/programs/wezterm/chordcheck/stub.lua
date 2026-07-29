-- Minimal `wezterm` stand-in, enough to load keybindings.lua outside the
-- WezTerm host and read back the chords it binds.
--
-- Why a stub rather than a Nix-side declaration of the chords: a declaration
-- has to be kept in step with the Lua by hand, and a chord list that disagrees
-- with the bindings is the same class of drift that let the guard patterns and
-- lib/allowlist.nix diverge. Reading the real table cannot drift.
--
-- Actions are represented as inert tables. The check only ever looks at `key`
-- and `mods`, so an action never has to do anything.
local M = {}

local function tag(name)
  return setmetatable({ __action = name }, {
    __call = function(_, arg)
      return { __action = name, arg = arg }
    end,
    __tostring = function()
      return name
    end,
  })
end

M.action = setmetatable({}, {
  __index = function(_, k)
    return tag(k)
  end,
})

M.action_callback = function(fn)
  return { __callback = true, fn = fn }
end

M.log_warn = function() end
M.log_error = function() end
M.log_info = function() end
M.on = function() end

-- nil on purpose: keybindings.lua guards on `wezterm.gui` for headless runs,
-- which is exactly the path this check exercises.
M.gui = nil

M.plugin = {
  list = function()
    return {}
  end,
  require = function()
    error("plugin loading is not available under the chord-extraction stub")
  end,
}

-- Both are pcall-guarded by keybindings.lua; erroring here drives it down its
-- own fallback path rather than the machine's real ssh config.
M.enumerate_ssh_hosts = function()
  error("no ssh host enumeration under the stub")
end

M.shell_split = function(s)
  return { s }
end

M.font_with_fallback = function(x)
  return x
end
M.format = function(x)
  return x
end
M.strftime = function()
  return ""
end

-- Shape-compatible with the real config.json/env.json the loader reads. Values
-- are irrelevant; only the keys have to exist.
M.json_parse = function(_)
  return {
    plugins = {},
    font = { monospace = "stub", symbols = "stub" },
    transparency = { opacity = 1, blur = 0 },
    colors = {},
    PATH = "/usr/bin",
    TERMINFO_DIRS = "/usr/share/terminfo",
  }
end

M.config_builder = nil
M.home_dir = "/nonexistent"
M.target_triple = "aarch64-apple-darwin"

return M
