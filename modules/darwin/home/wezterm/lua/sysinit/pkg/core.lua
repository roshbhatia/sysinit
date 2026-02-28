local M = {}

local function get_basic_config()
  local ssh_domains = {
    {
      name = "vorgossos",
      remote_address = "vorgossos.stork-eel.ts.net",
      username = "rshnbhatia",
      assume_shell = "Posix",

      default_prog = { "bash" },
    },
    {
      name = "huey",
      remote_address = "huey.taila415c.ts.net",
      username = "rosh",
      multiplexing = "None",
      assume_shell = "Posix",
      default_prog = { "zsh" },
    },
  }

  return {
    ssh_domains = ssh_domains,
  }
end

function M.setup(config)
  local basic_config = get_basic_config()

  for key, value in pairs(basic_config) do
    config[key] = value
  end
end

return M
