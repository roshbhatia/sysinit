-- AI Hooks: Integration with Claude Code hooks system
local M = {}
local uv = vim.loop

-- Hook configurations
local hook_configs = {}

-- Hook event types (from Claude Code documentation)
local HOOK_EVENTS = {
  PRE_TOOL_USE = "PreToolUse",
  POST_TOOL_USE = "PostToolUse",
  USER_PROMPT_SUBMIT = "UserPromptSubmit",
  NOTIFICATION = "Notification",
  STOP = "Stop",
  SUBAGENT_STOP = "SubagentStop",
  SESSION_START = "SessionStart",
  SESSION_END = "SessionEnd",
  PRE_COMPACT = "PreCompact",
}

-- Register hook
function M.register(event, matcher, command, opts)
  opts = opts or {}

  if not hook_configs[event] then
    hook_configs[event] = {}
  end

  table.insert(hook_configs[event], {
    matcher = matcher,
    command = command,
    timeout = opts.timeout or 60000,
    type = opts.type or "command",
  })
end

-- Execute hook
function M.execute(event, input_data, callback)
  local hooks = hook_configs[event]
  if not hooks or #hooks == 0 then
    if callback then
      callback(true)
    end
    return
  end

  local results = {}
  local pending = #hooks

  for _, hook in ipairs(hooks) do
    -- Check matcher
    local should_execute = true
    if hook.matcher and input_data.tool_name then
      if not input_data.tool_name:match(hook.matcher) then
        should_execute = false
        pending = pending - 1
        if pending == 0 and callback then
          callback(true, results)
        end
      end
    end

    if should_execute then
      -- Execute command
      M._execute_command(hook, input_data, function(success, output)
        table.insert(results, {
          hook = hook,
          success = success,
          output = output,
        })

        pending = pending - 1
        if pending == 0 and callback then
          -- Process results
          local should_continue = true
          local messages = {}

          for _, result in ipairs(results) do
            if not result.success then
              should_continue = false
              table.insert(messages, result.output.stderr or result.output.message)
            elseif result.output.decision == "block" then
              should_continue = false
              table.insert(messages, result.output.reason)
            end
          end

          callback(should_continue, messages)
        end
      end)
    end
  end
end

-- Execute command with timeout
function M._execute_command(hook, input_data, callback)
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local stdout_chunks = {}
  local stderr_chunks = {}
  local timer = nil

  -- Prepare environment
  local env = vim.fn.environ()
  env.CLAUDE_PROJECT_DIR = vim.fn.getcwd()

  local env_list = {}
  for k, v in pairs(env) do
    table.insert(env_list, k .. "=" .. v)
  end

  -- Spawn process
  local handle, pid = uv.spawn("sh", {
    args = { "-c", hook.command },
    stdio = { stdin, stdout, stderr },
    env = env_list,
  }, function(code, signal)
    if timer then
      timer:stop()
      timer:close()
    end

    stdin:close()
    stdout:close()
    stderr:close()

    local stdout_str = table.concat(stdout_chunks)
    local stderr_str = table.concat(stderr_chunks)

    -- Process output
    local output = M._process_output(code, stdout_str, stderr_str)

    vim.schedule(function()
      callback(code == 0 or code == 2, output)
    end)
  end)

  if not handle then
    callback(false, { message = "Failed to execute hook command" })
    return
  end

  -- Setup timeout
  timer = uv.new_timer()
  timer:start(hook.timeout, 0, function()
    if handle then
      handle:kill("sigterm")
    end
  end)

  -- Setup output readers
  stdout:read_start(function(err, data)
    if data then
      table.insert(stdout_chunks, data)
    end
  end)

  stderr:read_start(function(err, data)
    if data then
      table.insert(stderr_chunks, data)
    end
  end)

  -- Send input
  stdin:write(vim.json.encode(input_data) .. "\n", function()
    stdin:shutdown()
  end)
end

-- Process hook output
function M._process_output(exit_code, stdout, stderr)
  local output = {
    exit_code = exit_code,
    stdout = stdout,
    stderr = stderr,
  }

  -- Try to parse JSON output
  if stdout and stdout ~= "" then
    local ok, json = pcall(vim.json.decode, stdout)
    if ok then
      output = vim.tbl_extend("force", output, json)
    end
  end

  -- Handle exit code 2 (blocking error)
  if exit_code == 2 then
    output.decision = "block"
    output.reason = stderr
  end

  return output
end

-- Create input data for hooks
function M.create_input(event, data)
  local base = {
    session_id = data.session_id or vim.fn.tempname(),
    transcript_path = data.transcript_path,
    cwd = vim.fn.getcwd(),
    hook_event_name = event,
  }

  if event == HOOK_EVENTS.PRE_TOOL_USE or event == HOOK_EVENTS.POST_TOOL_USE then
    base.tool_name = data.tool_name
    base.tool_input = data.tool_input
    if event == HOOK_EVENTS.POST_TOOL_USE then
      base.tool_response = data.tool_response
    end
  elseif event == HOOK_EVENTS.USER_PROMPT_SUBMIT then
    base.prompt = data.prompt
  elseif event == HOOK_EVENTS.NOTIFICATION then
    base.message = data.message
  elseif event == HOOK_EVENTS.SESSION_START then
    base.source = data.source or "startup"
  elseif event == HOOK_EVENTS.SESSION_END then
    base.reason = data.reason or "exit"
  elseif event == HOOK_EVENTS.PRE_COMPACT then
    base.trigger = data.trigger or "manual"
    base.custom_instructions = data.custom_instructions or ""
  end

  return base
end

-- Load hooks from settings
function M.load_from_settings()
  local settings_paths = {
    vim.fn.expand("~/.claude/settings.json"),
    vim.fn.getcwd() .. "/.claude/settings.json",
    vim.fn.getcwd() .. "/.claude/settings.local.json",
  }

  for _, path in ipairs(settings_paths) do
    if vim.fn.filereadable(path) == 1 then
      local content = vim.fn.readfile(path)
      local ok, settings = pcall(vim.json.decode, table.concat(content, "\n"))

      if ok and settings.hooks then
        M._load_hooks(settings.hooks)
      end
    end
  end
end

-- Load hooks from configuration
function M._load_hooks(hooks_config)
  for event, configs in pairs(hooks_config) do
    for _, config in ipairs(configs) do
      if config.hooks then
        for _, hook in ipairs(config.hooks) do
          M.register(event, config.matcher, hook.command, {
            timeout = hook.timeout,
            type = hook.type,
          })
        end
      end
    end
  end
end

-- Initialize hooks
function M.setup(opts)
  opts = opts or {}

  -- Load from settings files
  if opts.load_settings ~= false then
    M.load_from_settings()
  end

  -- Register custom hooks
  if opts.hooks then
    M._load_hooks(opts.hooks)
  end
end

M.EVENTS = HOOK_EVENTS

return M
