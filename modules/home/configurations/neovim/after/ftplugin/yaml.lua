vim.opt_local.foldlevel = 99

-- Validation via :make (yq validates YAML by attempting to parse it)
vim.opt_local.makeprg = "yq . % > /dev/null"
vim.opt_local.errorformat = [[%Ein "%f"\, line %l\, column %c.,%-G%.%#]]

Snacks.keymap.set("n", "<localleader>v", "<cmd>make<cr>", { ft = "yaml", desc = "Validate syntax" })

vim.api.nvim_buf_create_user_command(0, "YamlSchema", function(opts)
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(opts.bang)
end, {
  desc = "Select YAML schema (auto-detects K8s). Use ! to force show all schemas.",
  bang = true,
})

Snacks.keymap.set("n", "<localleader>s", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(false)
end, {
  desc = "Select YAML schema",
  buffer = true,
})
