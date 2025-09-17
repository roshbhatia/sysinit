-- AI Server Manager: Manages AI service processes
local M = {}
local uv = vim.loop

-- Server instances
local servers = {}

local server_configs = {
  goose = {
    command = "goose",
  },
  claude = {
    command = "claude",
    args = {
      "--add-dir",
      vim.fn.getcwd(),
    },
  },
  cursor = {
    command = "cursor-agent",
    args = {
      "--with-diffs",
    },
  },
  opencode = {
    command = "opencode",
    args = {
      "--port",
      "9103",
    },
    port = 9103,
  },
}

-- Start server
function M.start(provider, opts)
  opts = opts or {}
  local config = vim.tbl_deep_extend("force", server_configs[provider] or {}, opts)

  if servers[provider] and servers[provider].handle then
    return true, servers[provider].port
  end

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local env = vim.tbl_extend("force", vim.fn.environ(), config.env or {})
  local env_list = {}
  for k, v in pairs(env) do
    table.insert(env_list, k .. "=" .. v)
  end

  local handle, pid = uv.spawn(config.command, {
    args = config.args,
    stdio = { nil, stdout, stderr },
    env = env_list,
  }, function(code, signal)
    servers[provider].handle = nil
    servers[provider].pid = nil
    vim.schedule(function()
      vim.notify(
        string.format("%s server exited (code: %s, signal: %s)", provider, code, signal),
        vim.log.levels.INFO
      )
    end)
  end)

  if not handle then
    return false, "Failed to start " .. provider .. " server"
  end

  servers[provider] = {
    handle = handle,
    pid = pid,
    port = config.port,
    stdout = stdout,
    stderr = stderr,
    logger = opts.logger,
  }

  -- Setup output handlers
  M._setup_output_handler(provider, stdout, "stdout")
  M._setup_output_handler(provider, stderr, "stderr")

  -- Wait for server to be ready
  vim.defer_fn(function()
    if M.check_port(config.port) then
      vim.schedule(function()
        vim.notify(provider .. " server started on port " .. config.port, vim.log.levels.INFO)
      end)
    end
  end, 1000)

  return true, config.port
end

-- Setup output handler
function M._setup_output_handler(provider, pipe, stream_type)
  if not pipe then
    return
  end

  pipe:read_start(function(err, data)
    if err then
      return
    end

    if data then
      local server = servers[provider]
      if server and server.logger then
        server.logger:log(stream_type, data)
      end

      -- Emit events for important messages
      if data:match("ready") or data:match("listening") then
        vim.api.nvim_exec_autocmds("User", {
          pattern = "AI" .. provider .. "Ready",
          data = { message = data },
        })
      end
    end
  end)
end

-- Stop server
function M.stop(provider)
  local server = servers[provider]
  if not server or not server.handle then
    return false, "Server not running"
  end

  server.handle:kill("sigterm")

  -- Force kill after timeout
  vim.defer_fn(function()
    if server.handle then
      server.handle:kill("sigkill")
    end
  end, 5000)

  return true
end

-- Restart server
function M.restart(provider, opts)
  M.stop(provider)
  vim.defer_fn(function()
    M.start(provider, opts)
  end, 500)
end

-- Check if port is in use
function M.check_port(port)
  local socket = uv.new_tcp()
  local ok = pcall(function()
    socket:connect("127.0.0.1", port, function(err)
      socket:close()
    end)
  end)
  return ok
end

-- Get server info
function M.get_info(provider)
  local server = servers[provider]
  if not server then
    return nil
  end

  return {
    running = server.handle ~= nil,
    pid = server.pid,
    port = server.port,
  }
end

-- List all servers
function M.list()
  local list = {}
  for provider, _ in pairs(server_configs) do
    local info = M.get_info(provider)
    list[provider] = info or { running = false }
  end
  return list
end

-- Stop all servers on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for provider, _ in pairs(servers) do
      M.stop(provider)
    end
  end,
})

return M
