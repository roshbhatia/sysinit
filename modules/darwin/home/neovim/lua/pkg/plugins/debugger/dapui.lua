local M = {}

M.plugins = {{
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = {"mfussenegger/nvim-dap"}
}}

function M.setup()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup({
        -- ...existing dapui configuration...
    })

    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end
    -- ...existing listeners...
end

return M
