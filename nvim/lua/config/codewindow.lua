-- Check if code preview should be enabled
if vim.g.code_preview_enabled == nil then
    vim.g.code_preview_enabled = true -- default to true
end

require('codewindow').setup()
