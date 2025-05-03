local M = {}

M.plugins = {{
    "rcarriga/nvim-dap-ui",
    lazy = true,
    event = "VeryLazy",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end

        vim.api.nvim_create_user_command('DapUIToggle', function()
            dapui.toggle()
        end, {})
        vim.api.nvim_create_user_command('DapUIFloat', function()
            dapui.float_element("scopes")
        end, {})
    end
}}

return M
