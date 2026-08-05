-- Antigravity CLI (`agy`) is the Gemini-family harness; the standalone
-- `gemini` CLI is retired and is no longer installed. Flags below are read
-- from `agy --help`, not carried over from the gemini adapter. The two share
-- almost no surface (agy has no --yolo, --approval-mode, or --resume).
--
-- agy exposes no MCP flag, so it cannot receive a per-session nvim control
-- server. See doc/agent-ide-integration.md.
return require("harness.adapters._shared").raw_cli_adapter({
  name = "antigravity",
  label = "󰊭  Antigravity",
  cmd = "agy",
  options_schema = {
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "sandbox", flag = "--sandbox", kind = "toggle" },
    { name = "dangerous", flag = "--dangerously-skip-permissions", kind = "toggle" },
    { name = "new_project", flag = "--new-project", kind = "toggle" },
    {
      name = "mode",
      flag = "--mode",
      kind = "enum",
      choices = { "accept-edits", "plan" },
    },
    {
      name = "effort",
      flag = "--effort",
      kind = "enum",
      choices = { "low", "medium", "high" },
    },
    { name = "model", flag = "--model", kind = "value", prompt = "Model" },
    { name = "agent", flag = "--agent", kind = "value", prompt = "Agent for this session" },
    { name = "conversation", flag = "--conversation", kind = "value", prompt = "Conversation to resume" },
    { name = "project", flag = "--project", kind = "value", prompt = "Project" },
    { name = "log_file", flag = "--log-file", kind = "value", prompt = "CLI log file path" },
    { name = "add_dir", flag = "--add-dir", kind = "list", prompt = "Extra dirs to allow (comma-separated)" },
  },
})
