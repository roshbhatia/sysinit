-- Goose Provider
local M = {}
local client = require("sysinit.ai.core.client")
local protocol = require("sysinit.ai.core.protocol")
local hooks = require("sysinit.ai.core.hooks")

M.name = "goose"
M.port = 9100
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

  -- Execute pre-hook
  local hook_input = hooks.create_input(hooks.EVENTS.USER_PROMPT_SUBMIT, {
    prompt = text,
    session_id = M.session_id,
  })

  hooks.execute(hooks.EVENTS.USER_PROMPT_SUBMIT, hook_input, function(should_continue, messages)
    if not should_continue then
      vim.notify("Prompt blocked: " .. table.concat(messages or {}, ", "), vim.log.levels.WARN)
      return
    end

    -- Send to goose
    M.client:send("prompt", msg, function(result, error)
      if error then
        vim.notify("Goose error: " .. vim.inspect(error), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.handle_sse(data)
  local event = protocol.parse_sse(data)
  if event then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "GooseSSE",
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
