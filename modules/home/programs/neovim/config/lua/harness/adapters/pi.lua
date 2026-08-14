local lifecycle = require("harness.lifecycle")

local lc

local function ensure_lifecycle()
  if not lc then
    lc = lifecycle.build("pi", { name = "pi", percent = 0.4 })
  end
  return lc
end

local function build_pi_cmd()
  local cmd = { "pi", "--mode", "rpc", "--no-session" }
  for _, arg in ipairs(require("harness.options").build_args("pi")) do
    table.insert(cmd, arg)
  end
  return cmd
end

return {
  name = "pi",
  label = "󰏿  Pi",
  options_schema = {
    { name = "no_tools", flag = "--no-tools", kind = "toggle" },
    { name = "no_builtin_tools", flag = "--no-builtin-tools", kind = "toggle" },
    { name = "fast", flag = "--fast", kind = "toggle" },
    { name = "plan", flag = "--plan", kind = "toggle" },
    { name = "verbose", flag = "--verbose", kind = "toggle" },
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "resume", flag = "--resume", kind = "toggle" },
    { name = "no_skills", flag = "--no-skills", kind = "toggle" },
    { name = "no_extensions", flag = "--no-extensions", kind = "toggle" },
    { name = "no_context_files", flag = "--no-context-files", kind = "toggle" },
    { name = "no_prompt_templates", flag = "--no-prompt-templates", kind = "toggle" },
    { name = "no_themes", flag = "--no-themes", kind = "toggle" },
    { name = "approve", flag = "--approve", kind = "toggle" },
    { name = "offline", flag = "--offline", kind = "toggle" },
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
    { name = "exclude_tools", flag = "--exclude-tools", kind = "value", prompt = "Tool denylist, comma-separated" },
    { name = "append_system_prompt", flag = "--append-system-prompt", kind = "value", prompt = "Text or file path" },
    { name = "preset", flag = "--preset", kind = "value", prompt = "Preset configuration name" },
    { name = "fork", flag = "--fork", kind = "value", prompt = "Session id or path to fork" },
    { name = "theme", flag = "--theme", kind = "value", prompt = "Theme file path" },
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
    return vim.fn.executable("pi") == 1
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
      vim.notify("pi: plugin not loadable", vim.log.levels.WARN)
      return
    end
    pi.run({
      message = text,
      bufnr = vim.api.nvim_get_current_buf(),
      cmd = build_pi_cmd(),
    })
  end,
  kill = function()
    if lc then
      lc.kill()
    end
  end,
}
