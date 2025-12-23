local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "opencode",
  label = "OpenCode",
  icon = "󰫼 ",
  cmd = "opencode",
  priority = common.priorities.opencode,
}
