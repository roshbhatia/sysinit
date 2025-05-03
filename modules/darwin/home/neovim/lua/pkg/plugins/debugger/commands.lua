local M = {}

function M.setup()
    local dap = require("dap")
    local dapui = require("dapui")

    vim.api.nvim_create_user_command('DapToggleBreakpoint', function()
        dap.toggle_breakpoint()
    end, {})
    vim.api.nvim_create_user_command('DapContinue', function()
        dap.continue()
    end, {})
    vim.api.nvim_create_user_command('DapStepOver', function()
        dap.step_over()
    end, {})
    vim.api.nvim_create_user_command('DapStepInto', function()
        dap.step_into()
    end, {})
    vim.api.nvim_create_user_command('DapStepOut', function()
        dap.step_out()
    end, {})
    vim.api.nvim_create_user_command('DapTerminate', function()
        dap.terminate()
    end, {})
    vim.api.nvim_create_user_command('DapUIToggle', function()
        dapui.toggle()
    end, {})
    vim.api.nvim_create_user_command('DapUIFloat', function()
        dapui.float_element("scopes")
    end, {})
end

return M
