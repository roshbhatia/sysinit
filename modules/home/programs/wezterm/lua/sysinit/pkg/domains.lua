local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")
local M = {}

local function read_known_hosts_hosts()
  local hosts = {}
  local seen = {}
  local file = io.open(utils.get_home_dir() .. "/.ssh/known_hosts", "r")
  if not file then
    return hosts
  end

  for line in file:lines() do
    if line ~= "" and not line:match("^%s*#") and not line:match("^|1|") and not line:match("^@") then
      local first = line:match("^(%S+)")
      if first then
        for token in first:gmatch("[^,]+") do
          local host = token:match("^%[([^%]]+)%]") or token
          if host ~= "" and not host:match("[*?]") and not seen[host] then
            seen[host] = true
            table.insert(hosts, host)
          end
        end
      end
    end
  end

  file:close()
  return hosts
end

local function ssh_key_options()
  local opts = {}
  local config_data = utils.load_json_file(utils.get_config_path("config.json"))
  local agent = config_data and config_data.ssh and config_data.ssh.agent_socket
  if agent then
    local ok, matches = pcall(wezterm.glob, agent)
    if not ok or #matches == 0 then
      agent = nil
    end
  end
  if not agent or agent == "" then
    agent = os.getenv("SSH_AUTH_SOCK")
  end
  if agent and agent ~= "" then
    opts.identityagent = agent
    opts.identitiesonly = "no"
  end
  local home = utils.get_home_dir()
  for _, name in ipairs({ "id_ed25519", "id_ecdsa", "id_rsa" }) do
    local path = home .. "/.ssh/" .. name
    local fh = io.open(path, "r")
    if fh then
      fh:close()
      opts.identityfile = path
      break
    end
  end
  return opts
end

function M.ssh()
  local key_options = ssh_key_options()
  local domains = {}
  local seen = {}
  local resolved_hostnames = {}

  local function add(host)
    host = host:lower()
    if host == "" or host:match("[*?]") or seen[host] or resolved_hostnames[host] then
      return
    end
    seen[host] = true
    table.insert(domains, {
      name = "ssh:" .. host,
      remote_address = host,
      multiplexing = "WezTerm",
      assume_shell = "Posix",
      ssh_option = key_options,
    })
  end

  local ok, hosts = pcall(wezterm.enumerate_ssh_hosts)
  if ok and hosts then
    for host, cfg in pairs(hosts) do
      if not host:match("%.host") then
        if type(cfg) == "table" and cfg.hostname then
          resolved_hostnames[cfg.hostname:lower()] = true
        end
        add(host)
      end
    end
  end

  for _, host in ipairs(read_known_hosts_hosts()) do
    add(host)
  end

  return domains
end

return M
