return require("harness.adapters._shared").raw_cli_adapter({
  name = "crush",
  label = "  Crush",
  cmd = "crush",
  options_schema = {
    { name = "yolo", flag = "--yolo", kind = "toggle" },
    { name = "continue", flag = "--continue", kind = "toggle" },
    { name = "debug", flag = "--debug", kind = "toggle" },
    { name = "session", flag = "--session", kind = "value", prompt = "Session id", picker_source = "crush" },
    { name = "cwd", flag = "--cwd", kind = "value", prompt = "Working directory" },
    { name = "data_dir", flag = "--data-dir", kind = "value", prompt = "Custom crush data directory" },
    { name = "host", flag = "--host", kind = "value", prompt = "Crush server host (e.g. unix:///tmp/crush.sock)" },
  },
})
