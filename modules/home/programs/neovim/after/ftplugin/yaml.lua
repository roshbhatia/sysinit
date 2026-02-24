vim.opt_local.foldlevel = 99

-- Validation via :make (yq validates YAML by attempting to parse it)
vim.opt_local.makeprg = "yq . % --colors > /dev/null"
vim.opt_local.errorformat = [[%Ein "%f"\, line %l\, column %c.,%-G%.%#]]

-- Auto-apply schema on buffer enter
vim.defer_fn(function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.auto_apply_schema()
end, 100)

Snacks.keymap.set("n", "<localleader>v", "<cmd>make<cr>", { ft = "yaml", desc = "Validate syntax" })

vim.api.nvim_buf_create_user_command(0, "YamlSchema", function(opts)
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(opts.bang)
end, {
  desc = "Select YAML schema (auto-detects K8s). Use ! to force show all schemas.",
  bang = true,
})

vim.api.nvim_buf_create_user_command(0, "YamlCacheSchema", function(opts)
  local yaml_schema = require("sysinit.utils.yaml_schema")
  local source = opts.args or ""

  if source == "url" or source == "" then
    yaml_schema.cache_schema_from_url()
  elseif source == "clipboard" then
    yaml_schema.cache_schema_from_clipboard()
  elseif source == "file" then
    yaml_schema.cache_schema_from_file()
  else
    vim.notify("Invalid source. Use: url, clipboard, or file", vim.log.levels.ERROR)
  end
end, {
  desc = "Cache a custom YAML schema (args: url, clipboard, file)",
  nargs = "?",
  complete = function()
    return { "url", "clipboard", "file" }
  end,
})

Snacks.keymap.set("n", "<localleader>xs", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(false)
end, {
  desc = "Select YAML schema",
  buffer = true,
})

Snacks.keymap.set("n", "<localleader>xu", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.cache_schema_from_url()
end, {
  desc = "Cache schema from URL",
  buffer = true,
})

Snacks.keymap.set("n", "<localleader>xc", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.cache_schema_from_clipboard()
end, {
  desc = "Cache schema from clipboard",
  buffer = true,
})

Snacks.keymap.set("n", "<localleader>xf", function()
  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.cache_schema_from_file()
end, {
  desc = "Cache schema from file",
  buffer = true,
})
