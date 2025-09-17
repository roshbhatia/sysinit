-- AI Protocol: Unified message protocol for AI services
local M = {}

-- Message types
M.MESSAGE_TYPES = {
  PROMPT = "prompt",
  COMMAND = "command",
  COMPLETION = "completion",
  CONTEXT = "context",
  DIAGNOSTIC = "diagnostic",
  TOOL_CALL = "tool_call",
  TOOL_RESULT = "tool_result",
  EVENT = "event",
}

-- Create prompt message
function M.create_prompt(text, context)
  return {
    type = M.MESSAGE_TYPES.PROMPT,
    text = text,
    context = context or {},
    timestamp = os.time(),
  }
end

-- Create command message
function M.create_command(command, args)
  return {
    type = M.MESSAGE_TYPES.COMMAND,
    command = command,
    args = args or {},
    timestamp = os.time(),
  }
end

-- Create context message with compact diagnostics
function M.create_context(data)
  local context = {
    type = M.MESSAGE_TYPES.CONTEXT,
    timestamp = os.time(),
  }

  -- Add cursor position
  if data.cursor then
    context.cursor = string.format("%s:%d:%d", data.cursor.file, data.cursor.line, data.cursor.col)
  end

  -- Add selection
  if data.selection then
    context.selection = data.selection
  end

  -- Add compact diagnostics
  if data.diagnostics then
    context.diagnostics = M._compact_diagnostics(data.diagnostics)
  end

  -- Add buffer content (truncated)
  if data.buffer then
    local content = data.buffer
    if #content > 8000 then
      content = content:sub(1, 8000) .. "\n...<truncated>"
    end
    context.buffer = content
  end

  -- Add visible content
  if data.visible then
    context.visible = data.visible
  end

  -- Add git diff
  if data.diff then
    context.diff = data.diff
  end

  -- Add code actions
  if data.code_actions then
    context.code_actions = data.code_actions
  end

  return context
end

-- Compact diagnostics for smaller payload
function M._compact_diagnostics(diagnostics)
  if not diagnostics or #diagnostics == 0 then
    return nil
  end

  local compact = {}
  local by_severity = {}

  -- Group by severity
  for _, diag in ipairs(diagnostics) do
    local severity = diag.severity or "INFO"
    if not by_severity[severity] then
      by_severity[severity] = {}
    end

    -- Create compact diagnostic entry
    local entry = string.format("L%d", diag.lnum + 1)
    if diag.col then
      entry = entry .. ":" .. diag.col
    end

    -- Truncate message if too long
    local msg = diag.message or ""
    if #msg > 100 then
      msg = msg:sub(1, 97) .. "..."
    end
    entry = entry .. " " .. msg

    table.insert(by_severity[severity], entry)
  end

  -- Format compact output
  for severity, entries in pairs(by_severity) do
    if #entries > 5 then
      -- If too many, just show count and first few
      table.insert(
        compact,
        string.format(
          "%s(%d): %s, ...",
          severity,
          #entries,
          table.concat(vim.list_slice(entries, 1, 3), "; ")
        )
      )
    else
      table.insert(compact, string.format("%s: %s", severity, table.concat(entries, "; ")))
    end
  end

  return table.concat(compact, " | ")
end

-- Create tool call message
function M.create_tool_call(name, params)
  return {
    type = M.MESSAGE_TYPES.TOOL_CALL,
    name = name,
    params = params,
    timestamp = os.time(),
  }
end

-- Create tool result message
function M.create_tool_result(tool_id, result, success)
  return {
    type = M.MESSAGE_TYPES.TOOL_RESULT,
    tool_id = tool_id,
    result = result,
    success = success ~= false,
    timestamp = os.time(),
  }
end

-- Parse SSE event
function M.parse_sse(data)
  if not data then
    return nil
  end

  local event = {}

  -- Parse event type
  local event_match = data:match("event:%s*(.-)\n")
  if event_match then
    event.type = event_match
  end

  -- Parse data
  local data_match = data:match("data:%s*(.*)")
  if data_match then
    -- Try to parse as JSON
    local ok, json = pcall(vim.json.decode, data_match)
    if ok then
      event.data = json
    else
      event.data = data_match
    end
  end

  -- Parse id
  local id_match = data:match("id:%s*(.-)\n")
  if id_match then
    event.id = id_match
  end

  return event
end

-- Format message for display
function M.format_for_display(message)
  if not message then
    return ""
  end

  local lines = {}

  if message.type == M.MESSAGE_TYPES.PROMPT then
    table.insert(lines, "🤔 " .. (message.text or ""))
  elseif message.type == M.MESSAGE_TYPES.DIAGNOSTIC then
    table.insert(lines, "🔍 Diagnostics: " .. (message.diagnostics or "None"))
  elseif message.type == M.MESSAGE_TYPES.TOOL_CALL then
    table.insert(lines, string.format("🔧 %s(%s)", message.name, vim.inspect(message.params)))
  elseif message.type == M.MESSAGE_TYPES.TOOL_RESULT then
    local status = message.success and "✅" or "❌"
    table.insert(lines, string.format("%s Result: %s", status, message.result or ""))
  end

  return table.concat(lines, "\n")
end

-- Validate message
function M.validate(message)
  if not message then
    return false, "Message is nil"
  end

  if not message.type then
    return false, "Message type is required"
  end

  if not vim.tbl_contains(vim.tbl_values(M.MESSAGE_TYPES), message.type) then
    return false, "Invalid message type: " .. message.type
  end

  return true
end

return M
