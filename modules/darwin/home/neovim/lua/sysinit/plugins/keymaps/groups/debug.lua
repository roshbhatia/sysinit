-- debug.lua
-- Debugging keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register debug group with the main keymaps module
    keymaps.register_group("d", keymaps.group_icons.debug .. " Debug", {
        {
            key = "b",
            desc = "Toggle Breakpoint",
            neovim_cmd = "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
            vscode_cmd = "editor.debug.action.toggleBreakpoint"
        },
        {
            key = "c",
            desc = "Continue/Start",
            neovim_cmd = "<cmd>lua require'dap'.continue()<CR>",
            vscode_cmd = "workbench.action.debug.start"
        },
        {
            key = "i",
            desc = "Step Into",
            neovim_cmd = "<cmd>lua require'dap'.step_into()<CR>",
            vscode_cmd = "workbench.action.debug.stepInto"
        },
        {
            key = "o",
            desc = "Step Over",
            neovim_cmd = "<cmd>lua require'dap'.step_over()<CR>",
            vscode_cmd = "workbench.action.debug.stepOver"
        },
        {
            key = "O",
            desc = "Step Out",
            neovim_cmd = "<cmd>lua require'dap'.step_out()<CR>",
            vscode_cmd = "workbench.action.debug.stepOut"
        },
        {
            key = "t",
            desc = "Toggle DAP UI",
            neovim_cmd = "<cmd>lua require'dapui'.toggle()<CR>",
            vscode_cmd = "workbench.debug.action.toggleRepl"
        }
    })
end

-- Add any debug-specific plugins here
M.plugins = {}

return M