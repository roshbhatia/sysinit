-- YAML-specific configuration and keymaps

-- Command to select YAML schema
vim.api.nvim_create_user_command("YamlSchema", function(opts)
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(opts.bang)
end, {
  desc = "Select YAML schema (auto-detects K8s). Use ! to force show all schemas.",
  bang = true,
  buffer = true,
})

-- Keymap: <localleader>s to select schema
Snacks.keymap.set("n", "<localleader>s", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(false)
end, {
  desc = "Select YAML schema",
  buffer = true,
})

-- Keymap: <localleader>S to force show all schemas
Snacks.keymap.set("n", "<localleader>S", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(true)
end, {
  desc = "Select YAML schema (force all)",
  buffer = true,
})
