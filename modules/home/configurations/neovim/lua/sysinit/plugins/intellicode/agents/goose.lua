local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "goose",
  label = "Goose",
  icon = "  ",
  cmd = "goose",
  priority = common.priorities.goose,
}
