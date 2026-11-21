return function(settings)
  return function(options)
    local command = options.command or {}
    if #command > 0 then
      local environment = { PATH = settings.path }
      for name, value in pairs(options.environment or {}) do
        if not name:match("^[%a_][%w_]*$") or type(value) ~= "string" then
          error("Invalid picker environment variable: " .. name)
        end
        environment[name] = value
      end
      local argv = { "/usr/bin/env" }
      for name, value in pairs(environment) do
        argv[#argv + 1] = name .. "=" .. value
      end
      for _, value in ipairs(command) do
        argv[#argv + 1] = value
      end
      command = argv
    else
      command = settings.shell
    end

    return rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      label = options.label,
      options = {
        cwd = options.cwd,
        shell = #command > 0 and "none" or nil,
        command = #command > 0 and command or nil,
      },
    })
  end
end
