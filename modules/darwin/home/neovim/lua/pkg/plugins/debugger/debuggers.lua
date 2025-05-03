local M = {}

function M.setup()
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

return M
