vim.api.nvim_create_user_command("SysinitEditorQuery", function()
  local query = vim.json.decode(assert(vim.env.SYSINIT_EDITOR_QUERY))
  vim.env.SYSINIT_EDITOR_QUERY = nil
  require("sysinit_workbench." .. query.tool).open(query)
end, {})

vim.api.nvim_create_user_command("SysinitChanges", function()
  require("sysinit_workbench.changes").open({ program = "changes", args = { "interactive" } })
end, {})

vim.api.nvim_create_user_command("Traces", function(command)
  local args = command.args == "" and {} or { "--session", command.args }
  require("sysinit_workbench.traces").open({ program = "traces", args = args })
end, { nargs = "?" })

vim.api.nvim_create_user_command("SysinitAgentReview", function()
  require("sysinit_workbench.review").open()
end, {})
