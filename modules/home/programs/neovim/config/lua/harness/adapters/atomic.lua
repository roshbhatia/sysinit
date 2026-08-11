local lifecycle = require("harness.lifecycle")

local lc

local function ensure_lifecycle()
  if not lc then
    lc = lifecycle.build("atomic", { name = "atomic", percent = 0.4 })
  end
  return lc
end

local function build_atomic_cmd()
  local cmd = { "atomic", "--mode", "rpc", "--no-session" }
  for _, arg in ipairs(require("harness.options").build_args("atomic")) do
    table.insert(cmd, arg)
  end
  return cmd
end

return {
  name = "atomic",
  label = "󰬛  Atomic",
  -- Every flag read off `atomic --help` from the built store path. The three
  -- extension flags come from the packages this repository loads: `--fast` from
  -- @benvargas/pi-openai-fast, `--plan` from @plannotator/pi-extension, and
  -- `--mcp-config` from atomic's bundled @bastani/mcp.
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
    { name = "mcp_config", flag = "--mcp-config", kind = "value", prompt = "Path to MCP config file" },
    { name = "skill", flag = "--skill", kind = "list", prompt = "Skill files or dirs (comma-separated)" },
    { name = "extension", flag = "--extension", kind = "list", prompt = "Extension files (comma-separated)" },
  },
  available = function()
    return vim.fn.executable("atomic") == 1
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
      vim.notify("atomic: pi.nvim not loadable", vim.log.levels.WARN)
      return
    end
    -- pi.nvim spawns whatever `cmd` names, so it drives atomic unchanged. It
    -- holds one module-level `active_session` though, so a send while pi is
    -- mid-run is refused with pi.nvim's own "already running" notice. The pane
    -- routes above are keyed on the adapter name and stay independent.
    pi.run({
      message = text,
      bufnr = vim.api.nvim_get_current_buf(),
      cmd = build_atomic_cmd(),
    })
  end,
  kill = function()
    if lc then
      lc.kill()
    end
  end,
}
