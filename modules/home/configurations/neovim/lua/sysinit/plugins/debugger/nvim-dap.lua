local M = {}

M.plugins = {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      local dap = require("dap")

      dap.adapters.bashdb = {
        type = "executable",
        command = "bash-debug-adapter",
        name = "bashdb",
      }

      dap.configurations.sh = {
        {
          type = "bashdb",
          request = "launch",
          name = "Launch file",
          showDebugOutput = true,
          trace = true,
          file = "${file}",
          program = "${file}",
          cwd = "${workspaceFolder}",
          args = {},
          argsString = "",
          env = {},
          terminalKind = "integrated",
        },
      }
    end,
    keys = function()
      local dap = require("dap")
      return {
        {
          "<leader>db",
          function()
            dap.toggle_breakpoint()
          end,
          desc = "Toggle breakpoint",
        },
        {
          "<leader>dc",
          function()
            dap.continue()
          end,
          desc = "Continue",
        },
        {
          "<leader>dt",
          function()
            dap.run_to_cursor()
          end,
          desc = "Run to cursor",
        },
        {
          "<leader>dB",
          function()
            dap.clear_breakpoints()
          end,
          desc = "Clear breakpoints",
        },
        {
          "<leader>dr",
          function()
            dap.run()
          end,
          desc = "Run",
        },
        {
          "<leader>dR",
          function()
            dap.restart()
          end,
          desc = "Restart",
        },
        {
          "<leader>dx",
          function()
            dap.terminate()
          end,
          desc = "Terminate",
        },
        {
          "<leader>di",
          function()
            dap.step_into()
          end,
          desc = "Step into",
        },
        {
          "<leader>do",
          function()
            dap.step_over()
          end,
          desc = "Step over",
        },
        {
          "<leader>da",
          function()
            local args = vim.fn.input("Args: ")
            if args == nil or args == "" then
              return
            end
            local config = vim.deepcopy(dap.configurations.sh[1])
            config.args = vim.split(args, " ")
            dap.run(config)
          end,
          desc = "Run with args (prompt)",
        },
        {
          "<leader>dh",
          function()
            require("dap.ui.widgets").hover()
          end,
          desc = "DAP Hover",
        },
        {
          "<leader>dp",
          function()
            require("dap.ui.widgets").preview()
          end,
          desc = "DAP Preview",
        },
      }
    end,
  },
}

return M
