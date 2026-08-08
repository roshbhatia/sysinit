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

M.gui = nil

M.plugin = {
  list = function()
    return {}
  end,
  require = function()
    error("plugin loading is not available under the chord-extraction stub")
  end,
}

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
