vim.opt_local.foldlevel = 99

-- Validation via :make (yq validates YAML by attempting to parse it)
vim.opt_local.makeprg = "yq . % --colors > /dev/null"
vim.opt_local.errorformat = [[%Ein "%f"\, line %l\, column %c.,%-G%.%#]]
