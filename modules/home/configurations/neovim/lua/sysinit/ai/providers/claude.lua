-- Claude Code Provider
local M = {}
local client = require("sysinit.ai.core.client")
local protocol = require("sysinit.ai.core.protocol")
local hooks = require("sysinit.ai.core.hooks")

M.name = "claude"
M.port = 9101
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

  -- Create message with context
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

    -- Send to claude
    M.client:send("prompt", msg, function(result, error)
      if error then
        vim.notify("Claude error: " .. vim.inspect(error), vim.log.levels.ERROR)
      else
        -- Execute post-hook for tool usage
        if result and result.tool_calls then
          for _, tool_call in ipairs(result.tool_calls) do
            local tool_hook_input = hooks.create_input(hooks.EVENTS.POST_TOOL_USE, {
              tool_name = tool_call.name,
              tool_input = tool_call.params,
              tool_response = tool_call.result,
              session_id = M.session_id,
            })
            hooks.execute(hooks.EVENTS.POST_TOOL_USE, tool_hook_input)
          end
        end
      end
    end)
  end)
end

function M.handle_sse(data)
  local event = protocol.parse_sse(data)
  if event then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "ClaudeSSE",
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
