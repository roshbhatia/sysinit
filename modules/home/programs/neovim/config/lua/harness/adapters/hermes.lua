return require("harness.adapters._shared").raw_cli_adapter({
  name = "hermes",
  label = "󱙺  Hermes",
  cmd = "hermes",
  -- Bare `hermes` opens the interactive session; `chat` names it, so the
  -- command line reads the same as the one the docs give.
  args = { "chat" },
  options_schema = {
    { name = "tui", flag = "--tui", kind = "toggle" },
    { name = "cli", flag = "--cli", kind = "toggle" },
    { name = "worktree", flag = "--worktree", kind = "toggle" },
    { name = "yolo", flag = "--yolo", kind = "toggle" },
    { name = "safe_mode", flag = "--safe-mode", kind = "toggle" },
    { name = "ignore_user_config", flag = "--ignore-user-config", kind = "toggle" },
    { name = "model", flag = "--model", kind = "value", prompt = "Model" },
    { name = "provider", flag = "--provider", kind = "value", prompt = "Inference provider" },
    { name = "reasoning", flag = "--reasoning", kind = "value", prompt = "Reasoning level" },
    { name = "toolsets", flag = "--toolsets", kind = "list", prompt = "Toolsets (comma-separated)" },
    { name = "skills", flag = "--skills", kind = "list", prompt = "Skills to preload (comma-separated)" },
    { name = "resume", flag = "--resume", kind = "value", prompt = "Session to resume" },
    { name = "in_dir", flag = "--in", kind = "value", prompt = "Working directory" },
  },
})
