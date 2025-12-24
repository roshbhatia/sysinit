local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "copilot",
  label = "Copilot",
  icon = "  ",
  cmd = "copilot --allow-all-paths",
  priority = common.priorities.copilot,
}
