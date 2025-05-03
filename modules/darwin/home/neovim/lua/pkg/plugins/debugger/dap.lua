local M = {}

M.plugins = {{
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {"rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio"}
}}

function M.setup()
    require("pkg.plugins.debugger.signs").setup()
    require("pkg.plugins.debugger.debuggers").setup()
    require("pkg.plugins.debugger.dapui").setup()
    require("pkg.plugins.debugger.commands").setup()

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "dap-repl",
        callback = function()
            require("dap.ext.autocompl").attach()
        end
    })

    require("dap").defaults.fallback.terminal_win_cmd = "50vsplit new"
end

return M
