local M = {}

M.plugins = {{
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
    },
    lazy = true,
    config = function()
        -- DAP configuration will go here
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>d", "Debug", {
            {"b", function() require("dap").toggle_breakpoint() end, "Toggle Breakpoint"},
            {"c", function() require("dap").continue() end, "Continue/Start"},
            {"o", function() require("dap").step_over() end, "Step Over"},
            {"i", function() require("dap").step_into() end, "Step Into"},
            {"r", function() require("dap").restart() end, "Restart"},
            {"t", function() require("dap").terminate() end, "Terminate"},
            {"u", function() require("dapui").toggle() end, "Toggle UI"},
        })
    end
}}

return M