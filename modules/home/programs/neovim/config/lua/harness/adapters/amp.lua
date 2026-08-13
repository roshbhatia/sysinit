local lifecycle = require("harness.lifecycle")

local lc
local lc_signature

local function build_amp_parts()
  local options = require("harness.options")
  local sel = options.get_selected("amp")
  local parts = { "amp" }
  if sel.thread then
    table.insert(parts, "threads")
    table.insert(parts, "continue")
    if sel.thread_last then
      table.insert(parts, "--last")
    end
  end
  for _, arg in ipairs(options.build_args("amp")) do
    table.insert(parts, arg)
  end
  return parts
end

local function build_cmd_string()
  local parts = build_amp_parts()
  if #parts == 1 then
    return parts[1]
  end
  local rest = {}
  for i = 2, #parts do
    rest[i - 1] = vim.fn.shellescape(parts[i])
  end
  return parts[1] .. " " .. table.concat(rest, " ")
end

local function ensure_lifecycle()
  local cmd = build_cmd_string()
  if not lc or lc_signature ~= cmd then
    if lc and lc.kill then
      pcall(lc.kill)
    end
    lc = lifecycle.build(cmd, { name = "amp", percent = 0.4 })
    lc_signature = cmd
  end
  return lc
end

local function amp_message_ok()
  return pcall(require, "amp.message")
end

return {
  name = "amp",
  label = "󰫤  Amp",
  options_schema = {
    {
      name = "mode",
      flag = "--mode",
      kind = "enum",
      choices = { "low", "medium", "high", "ultra" },
    },
    {
      name = "visibility",
      flag = "--visibility",
      kind = "enum",
      choices = { "private", "unlisted", "workspace", "group" },
    },
    { name = "no_ide", flag = "--no-ide", kind = "toggle" },
    { name = "no_notifications", flag = "--no-notifications", kind = "toggle" },
    -- `--no-fast` is the per-run form of `amp.agent.speed`, which amp documents only by
    -- saying "fast" is billed at a premium.
    { name = "fast", flag = "--fast", kind = "toggle" },
    { name = "no_fast", flag = "--no-fast", kind = "toggle" },
    -- The run-time half of `sysinit.llm.amp.remoteExecution`. Exposed as an
    -- explicit off switch rather than left to the default so a pane started on
    -- the work machine can be seen to refuse terminal access from ampcode.com.
    {
      name = "no_remote_control_terminal",
      flag = "--no-remote-control-terminal",
      kind = "toggle",
    },
    { name = "label", flag = "--label", kind = "list", prompt = "Thread labels (comma-separated)" },
    { name = "mcp_config", flag = "--mcp-config", kind = "value", prompt = "MCP JSON or config file path" },
    { name = "settings_file", flag = "--settings-file", kind = "value", prompt = "Custom settings file path" },
    { name = "log_level", flag = "--log-level", kind = "value", prompt = "Log level" },
    {
      name = "thread",
      flag = "threads continue",
      label = "resume via amp picker",
      kind = "toggle",
      cli = false,
    },
    {
      name = "thread_last",
      flag = "--last",
      label = "resume last thread (needs resume above)",
      kind = "toggle",
      cli = false,
    },
    {
      name = "submit",
      flag = "submit",
      label = "auto-submit on send",
      kind = "toggle",
      cli = false,
    },
  },
  available = function()
    return amp_message_ok() and vim.fn.executable("amp") == 1
  end,
  toggle = function()
    ensure_lifecycle().toggle()
  end,
  focus = function()
    ensure_lifecycle().focus()
  end,
  is_visible = function()
    if not lc then
      return false
    end
    return lc.is_visible()
  end,
  send = function(text, opts)
    opts = opts or {}
    local ok, msg = pcall(require, "amp.message")
    if not ok then
      vim.notify("amp: amp.message module not loadable", vim.log.levels.WARN)
      return
    end
    local sel = require("harness.options").get_selected("amp")
    local submit
    if sel.submit ~= nil then
      submit = sel.submit and true or false
    else
      submit = opts.submit ~= false
    end
    local fn = submit and msg.send_message or msg.send_to_prompt
    local sent_ok, sent = pcall(fn, text)
    if not sent_ok then
      vim.notify("amp: send error: " .. tostring(sent), vim.log.levels.WARN)
      return
    end
    if sent == false then
      vim.notify("amp: bridge has no connected client — toggle amp first (<leader>jj → amp)", vim.log.levels.WARN)
      return
    end
    vim.notify(string.format("amp: %s %d chars", submit and "submitted" or "appended", #text), vim.log.levels.INFO)
  end,
  kill = function()
    if lc then
      lc.kill()
      lc = nil
      lc_signature = nil
    end
  end,
}
