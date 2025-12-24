local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "claude",
  label = "Claude",
  icon = "  ",
  cmd = "claude --permission-mode plan",
  priority = common.priorities.claude,
}
