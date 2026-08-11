local lifecycle = require("harness.lifecycle")

local lc

local function ensure_lifecycle()
  if not lc then
    lc = lifecycle.build("prime-agent", { name = "prime-agent", percent = 0.4 })
  end
  return lc
end

local function build_prime_agent_cmd()
  local cmd = { "prime-agent", "--mode", "rpc", "--no-session" }
  for _, arg in ipairs(require("harness.options").build_args("prime-agent")) do
    table.insert(cmd, arg)
  end
  return cmd
end

return {
  name = "prime-agent",
  label = "󰙨  Prime Agent",
  -- Every flag was probed against the built store path rather than read off
  -- `--help`: prime-agent errors with `Unknown option: <flag>` on anything it
  -- does not take, so each entry here is a flag that a real run accepted.
  --
  -- Two differences from pi's and atomic's schemas, both measured:
  --   --resume is a value, not a toggle. Bare, it errors "requires a session
  --     id or path", so the toggle spelling the other two use would only ever
  --     produce a failed launch here.
  --   --approve and --exclude-tools are absent from this fork entirely.
  --
  -- `--fast` comes from @benvargas/pi-openai-fast and `--plan` from
  -- @plannotator/pi-extension; both are packages this repository loads, and
  -- neither appears in `--help` because prime-agent prints help before it loads
  -- extensions.
  --
  -- `--goal-token-budget` is deliberately omitted: it errors unless `--goal` is
  -- also passed, and the options schema has no way to express that dependency,
  -- so offering it alone would only ever produce a failed launch.
  options_schema = {
    { name = "no_tools", flag = "--no-tools", kind = "toggle" },
    { name = "no_builtin_tools", flag = "--no-builtin-tools", kind = "toggle" },
    { name = "fast", flag = "--fast", kind = "toggle" },
    { name = "plan", flag = "--plan", kind = "toggle" },
    { name = "verbose", flag = "--verbose", kind = "toggle" },
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "no_skills", flag = "--no-skills", kind = "toggle" },
    { name = "no_extensions", flag = "--no-extensions", kind = "toggle" },
    { name = "no_context_files", flag = "--no-context-files", kind = "toggle" },
    { name = "no_prompt_templates", flag = "--no-prompt-templates", kind = "toggle" },
    { name = "no_themes", flag = "--no-themes", kind = "toggle" },
    { name = "offline", flag = "--offline", kind = "toggle" },
    { name = "autonomous", flag = "--autonomous", kind = "toggle" },
    {
      name = "thinking",
      flag = "--thinking",
      kind = "enum",
      choices = { "off", "minimal", "low", "medium", "high", "xhigh", "max" },
    },
    { name = "provider", flag = "--provider", kind = "value", prompt = "Provider (e.g. anthropic, openai, google)" },
    { name = "model", flag = "--model", kind = "value", prompt = "Model pattern (e.g. anthropic/sonnet)" },
    { name = "models", flag = "--models", kind = "value", prompt = "Ctrl+P cycle patterns, comma-separated" },
    { name = "tools", flag = "--tools", kind = "value", prompt = "Tool allowlist, comma-separated" },
    { name = "resume", flag = "--resume", kind = "value", prompt = "Session id or path" },
    { name = "fork", flag = "--fork", kind = "value", prompt = "Session id or path to fork" },
    { name = "goal", flag = "--goal", kind = "value", prompt = "Persistent objective for a new root session" },
    { name = "append_system_prompt", flag = "--append-system-prompt", kind = "value", prompt = "Text or file path" },
    { name = "theme", flag = "--theme", kind = "value", prompt = "Theme file path" },
    { name = "autonomous_gate", flag = "--autonomous-gate", kind = "list", prompt = "Gate commands (comma-separated)" },
    { name = "skill", flag = "--skill", kind = "list", prompt = "Skill files or dirs (comma-separated)" },
    { name = "extension", flag = "--extension", kind = "list", prompt = "Extension files (comma-separated)" },
    {
      name = "prompt_template",
      flag = "--prompt-template",
      kind = "list",
      prompt = "Prompt template paths (comma-separated)",
    },
  },
  available = function()
    return vim.fn.executable("prime-agent") == 1
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
  send = function(text, _opts)
    local ok, pi = pcall(require, "pi")
    if not ok then
      vim.notify("prime-agent: pi.nvim not loadable", vim.log.levels.WARN)
      return
    end
    -- pi.nvim spawns whatever `cmd` names, so it drives prime-agent unchanged.
    -- It holds one module-level `active_session` though, so a send while pi or
    -- atomic is mid-run is refused with pi.nvim's own "already running" notice.
    -- The pane routes above are keyed on the adapter name and stay independent.
    pi.run({
      message = text,
      bufnr = vim.api.nvim_get_current_buf(),
      cmd = build_prime_agent_cmd(),
    })
  end,
  kill = function()
    if lc then
      lc.kill()
    end
  end,
}
