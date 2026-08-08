return require("harness.adapters._shared").raw_cli_adapter({
  name = "devin",
  label = "󰚩  Devin",
  cmd = "devin",
  options_schema = {
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "sandbox", flag = "--sandbox", kind = "toggle" },
    {
      name = "permission_mode",
      flag = "--permission-mode",
      kind = "enum",
      choices = { "auto", "accept-edits", "smart", "dangerous", "autonomous" },
    },
    {
      name = "respect_workspace_trust",
      flag = "--respect-workspace-trust",
      kind = "enum",
      choices = { "true", "false" },
    },
    { name = "resume", flag = "--resume", kind = "opt_value", prompt = "Session ID (blank opens the picker)" },
    { name = "export", flag = "--export", kind = "opt_value", prompt = "Export path (blank uses the default)" },
    {
      name = "model",
      flag = "--model",
      kind = "value",
      prompt = "Model (e.g. claude-sonnet-4, claude-opus-4.6, opus, codex)",
    },
    { name = "prompt_file", flag = "--prompt-file", kind = "value", prompt = "Path to prompt file" },
    { name = "agent_config", flag = "--agent-config", kind = "value", prompt = "Path to agent config (JSON/YAML)" },
    { name = "config", flag = "--config", kind = "value", prompt = "Path to config file" },
  },
})
