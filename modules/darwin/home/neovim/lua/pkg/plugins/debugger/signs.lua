local M = {}

function M.setup()
    vim.fn.sign_define('DapBreakpoint', {
        text = '',
        texthl = 'DiagnosticSignError',
        linehl = '',
        numhl = ''
    })
end

return M
