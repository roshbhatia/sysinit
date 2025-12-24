local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "cursor",
  label = "Cursor",
  icon = " ",
  cmd = "cursor-agent",
  priority = common.priorities.cursor,
}
