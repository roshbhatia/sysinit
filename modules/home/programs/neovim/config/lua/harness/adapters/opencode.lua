local function opencode_ok()
  return pcall(require, "opencode")
end

local function refresh_server_cmd()
  local in_wezterm = vim.env.WEZTERM_PANE ~= nil and vim.fn.executable("wezterm") == 1
  if not in_wezterm then
    return
  end

  local args = require("harness.options").build_args("opencode")
  local cmd = "opencode --port"
  if #args > 0 then
    cmd = cmd .. " " .. table.concat(args, " ")
  end

  local wt_ok, wt = pcall(require, "utils.wezterm_terminal")
  if not wt_ok then
    return
  end
  local server_opts = wt.build_server_callbacks(cmd, { name = "opencode", percent = 0.35 })

  local g = vim.g.opencode_opts or {}
  g.server = server_opts
  vim.g.opencode_opts = g
end

return {
  name = "opencode",
  label = "  OpenCode",
  options_schema = {
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "fork", flag = "--fork", kind = "toggle" },
    { name = "pure", flag = "--pure", kind = "toggle" },
    { name = "auto", flag = "--auto", kind = "toggle" },
    { name = "mini", flag = "--mini", kind = "toggle" },
    { name = "no_replay", flag = "--no-replay", kind = "toggle" },
    { name = "print_logs", flag = "--print-logs", kind = "toggle" },
    {
      name = "log_level",
      flag = "--log-level",
      kind = "enum",
      choices = { "DEBUG", "INFO", "WARN", "ERROR" },
    },
    {
      name = "model",
      flag = "--model",
      kind = "value",
      prompt = "provider/model (e.g. anthropic/claude-sonnet-4-5)",
    },
    { name = "agent", flag = "--agent", kind = "value", prompt = "Agent name" },
    { name = "session", flag = "--session", kind = "value", prompt = "Session id (kill server first; <leader>jx)" },
    { name = "hostname", flag = "--hostname", kind = "value", prompt = "Hostname to listen on" },
    { name = "replay_limit", flag = "--replay-limit", kind = "value", prompt = "Cap mini replay to newest N" },
  },
  available = function()
    return opencode_ok() and vim.fn.executable("opencode") == 1
  end,
  toggle = function()
    refresh_server_cmd()
    require("opencode").toggle()
  end,
  focus = function()
    require("opencode").toggle()
  end,
  is_visible = function()
    return false
  end,
  send = function(text, opts)
    opts = opts or {}
    require("opencode").prompt(text, { submit = opts.submit ~= false })
    pcall(function()
      require("opencode").toggle()
    end)
  end,
  kill = function()
    pcall(function()
      require("opencode").toggle()
    end)
  end,
}
