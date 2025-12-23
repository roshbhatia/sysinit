local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "crush",
  label = "Crush",
  icon = "󱝁 ",
  cmd = "crush",
  priority = common.priorities.crush,
}
