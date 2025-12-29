local common = require("sysinit.plugins.intellicode.agents.common")

return {
  name = "amp",
  label = "Amp",
  icon = "  ",
  cmd = "amp --ide",
  priority = common.priorities.amp,
}
