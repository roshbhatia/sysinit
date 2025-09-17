-- Cursor Agent Provider
local M = {}
local client = require("sysinit.ai.core.client")
local protocol = require("sysinit.ai.core.protocol")

M.name = "cursor"
M.port = 9102
M.client = nil

function M.setup(opts)
  opts = opts or {}
  M.port = opts.port or M.port

  -- Get or create client
  M.client = client.get_client(M.name, {
    port = M.port,
    logger = opts.logger,
    sse_handler = M.handle_sse,
  })
end

function M.send_prompt(text, context)
  if not M.client then
    M.setup()
  end

  -- Create message
  local msg = protocol.create_prompt(text, context)

  -- Send to cursor
  M.client:send("prompt", msg, function(result, error)
    if error then
      vim.notify("Cursor error: " .. vim.inspect(error), vim.log.levels.ERROR)
    end
  end)
end

function M.handle_sse(data)
  local event = protocol.parse_sse(data)
  if event then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "CursorSSE",
      data = event,
    })
  end
end

function M.get_status()
  return {
    connected = M.client and M.client.state == "connected",
    port = M.port,
    name = M.name,
  }
end

return M
