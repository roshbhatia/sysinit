-- AI Logger: Integration with Goose logging system
local M = {}
local uv = vim.loop

-- Goose log paths (from documentation)
local log_paths = {
  unix = {
    sessions = vim.fn.expand("~/.local/share/goose/sessions/"),
    logs = vim.fn.expand("~/.local/state/goose/logs/"),
    history = vim.fn.expand("~/.config/goose/history.txt"),
  },
  windows = {
    sessions = vim.fn.expand("$APPDATA/Block/goose/data/sessions/"),
    logs = vim.fn.expand("$APPDATA/Block/goose/data/logs/"),
    history = vim.fn.expand("$APPDATA/Block/goose/data/history.txt"),
  },
}

-- Detect OS and get paths
local function get_paths()
  if vim.fn.has("win32") == 1 then
    return log_paths.windows
  end
  return log_paths.unix
end

local paths = get_paths()

-- Logger class
local Logger = {}
Logger.__index = Logger

function Logger:new(provider, session_id)
  local self = setmetatable({}, Logger)
  self.provider = provider
  self.session_id = session_id or vim.fn.strftime("%Y%m%d_%H%M%S")
  self.session_file = nil
  self.log_file = nil
  self:_init_files()
  return self
end

function Logger:_init_files()
  -- Ensure directories exist
  vim.fn.mkdir(paths.sessions, "p")
  vim.fn.mkdir(paths.logs .. "ai/", "p")

  -- Create session file (JSONL format like Goose)
  local session_filename = string.format("%s-%s.jsonl", self.provider, self.session_id)
  self.session_file = paths.sessions .. session_filename

  -- Create log file
  local log_filename = string.format("%s-%s.log", self.provider, self.session_id)
  self.log_file = paths.logs .. "ai/" .. log_filename

  -- Write initial session entry
  self:write_session({
    role = "system",
    created = os.time(),
    content = {
      {
        type = "text",
        text = string.format("Session started for %s", self.provider),
      },
    },
  })
end

-- Write to session file (JSONL format)
function Logger:write_session(entry)
  if not self.session_file then
    return
  end

  local file = io.open(self.session_file, "a")
  if file then
    file:write(vim.json.encode(entry) .. "\n")
    file:close()
  end
end

-- Log message
function Logger:log(level, message, data)
  local entry = {
    timestamp = os.time(),
    level = level,
    message = message,
  }

  if data then
    entry.data = data
  end

  -- Write to log file
  if self.log_file then
    local file = io.open(self.log_file, "a")
    if file then
      file:write(
        string.format("[%s] %s: %s\n", vim.fn.strftime("%Y-%m-%d %H:%M:%S"), level:upper(), message)
      )
      if data then
        file:write("  Data: " .. vim.inspect(data) .. "\n")
      end
      file:close()
    end
  end
end

-- Convenience methods
function Logger:info(message, data)
  self:log("info", message, data)
end

function Logger:error(message, data)
  self:log("error", message, data)
end

function Logger:debug(message, data)
  self:log("debug", message, data)
end

function Logger:warn(message, data)
  self:log("warn", message, data)
end

-- Log user message
function Logger:log_user_message(content)
  self:write_session({
    role = "user",
    created = os.time(),
    content = {
      {
        type = "text",
        text = content,
      },
    },
  })
end

-- Log assistant response
function Logger:log_assistant_response(content, tool_calls)
  local entry = {
    role = "assistant",
    created = os.time(),
    content = {},
  }

  if content then
    table.insert(entry.content, {
      type = "text",
      text = content,
    })
  end

  if tool_calls then
    for _, call in ipairs(tool_calls) do
      table.insert(entry.content, {
        type = "tool_request",
        tool_id = call.id,
        tool_name = call.name,
        arguments = call.arguments,
      })
    end
  end

  self:write_session(entry)
end

-- Log tool result
function Logger:log_tool_result(tool_id, result, success)
  self:write_session({
    role = "tool",
    created = os.time(),
    content = {
      {
        type = "tool_response",
        tool_id = tool_id,
        result = result,
        success = success,
      },
    },
  })
end

-- Write to command history
function Logger:add_to_history(command)
  local file = io.open(paths.history, "a")
  if file then
    file:write(string.format("%s: %s\n", vim.fn.strftime("%Y-%m-%d %H:%M:%S"), command))
    file:close()
  end
end

-- Get session transcript
function Logger:get_transcript()
  if not self.session_file then
    return {}
  end

  local file = io.open(self.session_file, "r")
  if not file then
    return {}
  end

  local transcript = {}
  for line in file:lines() do
    local ok, entry = pcall(vim.json.decode, line)
    if ok then
      table.insert(transcript, entry)
    end
  end
  file:close()

  return transcript
end

-- Module functions
function M.new(provider, session_id)
  return Logger:new(provider, session_id)
end

-- Get all sessions for a provider
function M.get_sessions(provider)
  local sessions = {}
  local files = vim.fn.glob(paths.sessions .. provider .. "-*.jsonl", false, true)

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local session_id = name:match(provider .. "%-(.+)")
    if session_id then
      table.insert(sessions, {
        id = session_id,
        file = file,
        provider = provider,
      })
    end
  end

  return sessions
end

-- Clean old sessions
function M.cleanup_old_sessions(days)
  days = days or 30
  local cutoff = os.time() - (days * 24 * 60 * 60)

  local files = vim.fn.glob(paths.sessions .. "*.jsonl", false, true)
  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat and stat.mtime.sec < cutoff then
      os.remove(file)
    end
  end
end

return M
