-- AI Client: Unified client for all AI services
local M = {}
local uv = vim.loop

-- Client state
local clients = {}
local message_id = 0

-- Create a new client instance
function M.new(provider, opts)
  opts = opts or {}
  local client = {
    provider = provider,
    port = opts.port,
    socket = nil,
    callbacks = {},
    sse_handler = opts.sse_handler,
    logger = opts.logger,
    state = "disconnected",
    message_queue = {},
  }
  setmetatable(client, { __index = M })
  return client
end

-- Connect to server
function M:connect()
  if self.state == "connected" then
    return true
  end

  self.socket = uv.new_tcp()
  local success, err = pcall(function()
    self.socket:connect("127.0.0.1", self.port, function(connect_err)
      if connect_err then
        self.state = "error"
        if self.logger then
          self.logger:error("Connection failed: " .. connect_err)
        end
      else
        self.state = "connected"
        self:_start_read_loop()
        self:_process_queue()
        if self.logger then
          self.logger:info("Connected to " .. self.provider .. " on port " .. self.port)
        end
      end
    end)
  end)

  if not success then
    self.state = "error"
    return false, err
  end
  return true
end

-- Send message
function M:send(method, params, callback)
  message_id = message_id + 1
  local msg = {
    id = message_id,
    method = method,
    params = params or {},
    timestamp = os.time(),
  }

  if callback then
    self.callbacks[msg.id] = callback
  end

  if self.state ~= "connected" then
    table.insert(self.message_queue, msg)
    self:connect()
    return msg.id
  end

  self:_write(msg)
  return msg.id
end

-- Write message to socket
function M:_write(msg)
  if not self.socket then
    return
  end

  local data = vim.json.encode(msg) .. "\n"
  self.socket:write(data, function(write_err)
    if write_err and self.logger then
      self.logger:error("Write error: " .. write_err)
    elseif self.logger then
      self.logger:debug("Sent: " .. data)
    end
  end)
end

-- Process queued messages
function M:_process_queue()
  for _, msg in ipairs(self.message_queue) do
    self:_write(msg)
  end
  self.message_queue = {}
end

-- Start reading from socket
function M:_start_read_loop()
  if not self.socket then
    return
  end

  local buffer = ""
  self.socket:read_start(function(read_err, data)
    if read_err then
      if self.logger then
        self.logger:error("Read error: " .. read_err)
      end
      self:disconnect()
      return
    end

    if data then
      buffer = buffer .. data
      -- Process complete messages
      while true do
        local newline_pos = buffer:find("\n")
        if not newline_pos then
          break
        end

        local msg_str = buffer:sub(1, newline_pos - 1)
        buffer = buffer:sub(newline_pos + 1)

        -- Handle SSE events
        if msg_str:match("^data: ") then
          if self.sse_handler then
            self.sse_handler(msg_str:sub(7))
          end
        else
          -- Handle JSON response
          local ok, msg = pcall(vim.json.decode, msg_str)
          if ok then
            self:_handle_response(msg)
          end
        end
      end
    end
  end)
end

-- Handle response
function M:_handle_response(msg)
  if self.logger then
    self.logger:debug("Received: " .. vim.inspect(msg))
  end

  if msg.id and self.callbacks[msg.id] then
    local callback = self.callbacks[msg.id]
    self.callbacks[msg.id] = nil
    vim.schedule(function()
      callback(msg.result, msg.error)
    end)
  end

  -- Handle events
  if msg.event then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "AI" .. self.provider .. msg.event,
      data = msg.data,
    })
  end
end

-- Disconnect
function M:disconnect()
  if self.socket then
    self.socket:shutdown()
    self.socket:close()
    self.socket = nil
  end
  self.state = "disconnected"
  if self.logger then
    self.logger:info("Disconnected from " .. self.provider)
  end
end

-- Get or create client
function M.get_client(provider, opts)
  if not clients[provider] then
    clients[provider] = M.new(provider, opts)
  end
  return clients[provider]
end

return M
