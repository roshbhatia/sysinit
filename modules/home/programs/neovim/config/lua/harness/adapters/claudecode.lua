local function find_claude_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      local marker = vim.b[buf].snacks_terminal
      if marker and type(marker) == "table" then
        local cmd = marker.cmd
        if type(cmd) == "string" and cmd:find("claude", 1, true) then
          return buf
        end
        if type(cmd) == "table" and cmd[1] and tostring(cmd[1]):find("claude", 1, true) then
          return buf
        end
      end
      local name = vim.api.nvim_buf_get_name(buf)
      if name:find("claude", 1, true) then
        return buf
      end
    end
  end
  return nil
end

local function find_claude_window(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

local function chansend_to_buf(buf, text, submit)
  local chan = vim.b[buf].terminal_job_id
  if not chan then
    return false
  end
  local payload = submit and (text .. "\r") or text
  local ok = pcall(vim.api.nvim_chan_send, chan, payload)
  if ok then
    pcall(function()
      local win = find_claude_window(buf)
      if win then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
      end
    end)
  end
  return ok
end

local wt = require("utils.wezterm_terminal")

local function clipboard_fallback(text)
  pcall(vim.fn.setreg, "+", text)
  pcall(vim.fn.setreg, "*", text)
  vim.notify("claudecode: send failed — prompt copied to clipboard, paste into the Claude pane", vim.log.levels.WARN)
end

local function try_send(text, submit)
  local pane_id = vim.g.harness_wezterm_pane_claudecode
  if pane_id and wt.pane_alive_sync(pane_id) then
    if wt.send_text(pane_id, text, submit) then
      return true
    end
  end
  local buf = find_claude_terminal()
  if buf and chansend_to_buf(buf, text, submit) then
    return true
  end
  return false
end

return {
  name = "claudecode",
  label = "  Claude",
  options_schema = {
    { name = "dangerous", flag = "--dangerously-skip-permissions", kind = "toggle" },
    { name = "ide", flag = "--ide", kind = "toggle", default = true },
    {
      name = "permission_mode",
      flag = "--permission-mode",
      kind = "enum",
      default = "auto",
      choices = { "acceptEdits", "auto", "bypassPermissions", "manual", "dontAsk", "plan" },
    },
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "fork_session", flag = "--fork-session", kind = "toggle" },
    { name = "safe_mode", flag = "--safe-mode", kind = "toggle" },
    { name = "bare", flag = "--bare", kind = "toggle" },
    { name = "chrome", flag = "--chrome", kind = "toggle" },
    { name = "verbose", flag = "--verbose", kind = "toggle" },
    { name = "resume", flag = "--resume", kind = "opt_value", prompt = "Session ID or search term" },
    { name = "worktree", flag = "--worktree", kind = "opt_value", prompt = "Worktree name (blank generates one)" },
    { name = "from_pr", flag = "--from-pr", kind = "opt_value", prompt = "PR number or URL" },
    {
      name = "effort",
      flag = "--effort",
      kind = "enum",
      choices = { "low", "medium", "high", "xhigh", "max" },
    },
    { name = "agent", flag = "--agent", kind = "value", prompt = "Agent name" },
    {
      name = "model",
      flag = "--model",
      kind = "value",
      prompt = "Model alias or full name (e.g. opus, sonnet)",
    },
    {
      name = "fallback_model",
      flag = "--fallback-model",
      kind = "value",
      prompt = "Fallback model(s), comma-separated",
    },
    { name = "name", flag = "--name", kind = "value", prompt = "Display name for this session" },
    { name = "session_id", flag = "--session-id", kind = "value", prompt = "Session UUID" },
    { name = "add_dir", flag = "--add-dir", kind = "value", prompt = "Extra directory to allow" },
    { name = "settings", flag = "--settings", kind = "value", prompt = "Settings file path or JSON" },
    { name = "setting_sources", flag = "--setting-sources", kind = "value", prompt = "user,project,local" },
    { name = "tools", flag = "--tools", kind = "value", prompt = [[Tools (e.g. "Bash,Edit,Read", "" to disable)]] },
    {
      name = "allowed_tools",
      flag = "--allowed-tools",
      kind = "value",
      prompt = [[Allowed tools (e.g. "Bash(git *)")]],
    },
    { name = "disallowed_tools", flag = "--disallowed-tools", kind = "value", prompt = "Denied tools" },
    { name = "append_system_prompt", flag = "--append-system-prompt", kind = "value", prompt = "Text to append" },
  },
  available = function()
    return pcall(require, "claudecode") and vim.fn.executable("claude") == 1
  end,
  toggle = function()
    local args = require("harness.options").build_args("claudecode")
    if #args > 0 then
      vim.cmd("ClaudeCode " .. table.concat(args, " "))
    else
      vim.cmd("ClaudeCode")
    end
  end,
  focus = function()
    pcall(vim.cmd, "ClaudeCodeFocus")
  end,
  is_visible = function()
    local pane_id = vim.g.harness_wezterm_pane_claudecode
    if pane_id and wt.pane_alive_sync(pane_id) then
      return true
    end
    local buf = find_claude_terminal()
    return buf ~= nil and find_claude_window(buf) ~= nil
  end,
  send = function(text, opts)
    opts = opts or {}
    local submit = opts.submit ~= false

    if try_send(text, submit) then
      return
    end

    pcall(vim.cmd, "ClaudeCode")
    vim.defer_fn(function()
      if try_send(text, submit) then
        return
      end
      clipboard_fallback(text)
    end, 400)
  end,
  kill = function()
    local pane_id = vim.g.harness_wezterm_pane_claudecode
    if pane_id then
      vim.fn.jobstart({ "wezterm", "cli", "kill-pane", "--pane-id", tostring(pane_id) }, { detach = true })
      vim.g.harness_wezterm_pane_claudecode = nil
      return
    end
    local buf = find_claude_terminal()
    if buf then
      local win = find_claude_window(buf)
      if win then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end,
}
