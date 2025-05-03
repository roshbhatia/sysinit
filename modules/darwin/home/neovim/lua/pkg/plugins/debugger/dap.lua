-- sysinit.nvim.doc-url="https://github.com/mfussenegger/nvim-dap/wiki"
local plugin_family = {}

M.plugins = {{
    "mfussenegger/nvim-dap",
    lazy = true
}, {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = {"mfussenegger/nvim-dap"}
}, {
    "nvim-neotest/nvim-nio",
    lazy = true
}}

local function configure_debuggers()
    local dap = require("dap")

    dap.adapters.python = {
        type = 'executable',
        command = 'python',
        args = {'-m', 'debugpy.adapter'}
    }

    dap.configurations.python = {{
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        pythonPath = function()
            local venv_path = os.getenv('VIRTUAL_ENV')
            if venv_path then
                return venv_path .. '/bin/python'
            end
            return 'python'
        end
    }, {
        type = "python",
        request = "launch",
        name = "Launch with arguments",
        program = "${file}",
        args = function()
            return vim.split(vim.fn.input("Arguments: "), " ")
        end,
        pythonPath = function()
            local venv_path = os.getenv('VIRTUAL_ENV')
            if venv_path then
                return venv_path .. '/bin/python'
            end
            return 'python'
        end
    }}

    dap.adapters.nlua = function(callback, config)
        callback({
            type = 'server',
            host = config.host or "127.0.0.1",
            port = config.port or 8086
        })
    end

    dap.configurations.lua = {{
        type = 'nlua',
        request = 'attach',
        name = "Attach to running Neovim instance",
        host = function()
            return "127.0.0.1"
        end,
        port = function()
            return 8086
        end
    }}

    dap.adapters.node2 = {
        type = 'executable',
        command = 'node',
        args = {vim.fn.stdpath("data") .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js'}
    }

    dap.configurations.javascript = {{
        name = 'Launch',
        type = 'node2',
        request = 'launch',
        program = '${file}',
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = 'inspector',
        console = 'integratedTerminal'
    }, {
        name = 'Attach to process',
        type = 'node2',
        request = 'attach',
        processId = require('dap.utils').pick_process
    }}

    dap.configurations.typescript = dap.configurations.javascript
end

local function configure_dapui()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup({
        layouts = {{
            elements = {{
                id = "scopes",
                size = 0.25
            }, {
                id = "breakpoints",
                size = 0.25
            }, {
                id = "stacks",
                size = 0.25
            }, {
                id = "watches",
                size = 0.25
            }},
            size = 40,
            position = "left"
        }, {
            elements = {{
                id = "repl",
                size = 0.5
            }, {
                id = "console",
                size = 0.5
            }},
            size = 10,
            position = "bottom"
        }},
        controls = {
            enabled = true,
            element = "repl",
            icons = {
                pause = "",
                play = "",
                step_into = "",
                step_over = "",
                step_out = "",
                step_back = "",
                run_last = "",
                terminate = ""
            }
        }
    })

    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
    end
end

local function setup_dap_signs()
    vim.fn.sign_define('DapBreakpoint', {
        text = '',
        texthl = 'DiagnosticSignError',
        linehl = '',
        numhl = ''
    })
    vim.fn.sign_define('DapBreakpointCondition', {
        text = '',
        texthl = 'DiagnosticSignWarn',
        linehl = '',
        numhl = ''
    })
    vim.fn.sign_define('DapLogPoint', {
        text = '',
        texthl = 'DiagnosticSignInfo',
        linehl = '',
        numhl = ''
    })
    vim.fn.sign_define('DapStopped', {
        text = '',
        texthl = 'DiagnosticSignHint',
        linehl = 'DapStopped',
        numhl = ''
    })
    vim.fn.sign_define('DapBreakpointRejected', {
        text = '',
        texthl = 'DiagnosticSignError',
        linehl = '',
        numhl = ''
    })
end

local function setup_commands()
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

function plugin_family.setup()
    setup_dap_signs()
    configure_debuggers()
    configure_dapui()
    setup_commands()

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "dap-repl",
        callback = function()
            require("dap.ext.autocompl").attach()
        end
    })

    require("dap").defaults.fallback.terminal_win_cmd = "50vsplit new"
end

return plugin_family
