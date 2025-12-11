local M = {}

M.plugins = {
  {
    "mfussenegger/nvim-dap",
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    end,
    keys = {
      {
        "<leader>ceb",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>cec",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>cet",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>ceB",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear breakpoints",
      },
      {
        "<leader>cer",
        function()
          require("dap").run()
        end,
        desc = "Run",
      },
      {
        "<leader>ceR",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ces",
        function()
          require("dap").restart()
        end,
        desc = "Restart",
      },
      {
        "<leader>cex",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>cei",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>ceo",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
    },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>dt",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>dB",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear breakpoints",
      },
      {
        "<leader>dr",
        function()
          require("dap").run()
        end,
        desc = "Run",
      },
      {
        "<leader>dD",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>dR",
        function()
          require("dap").restart()
        end,
        desc = "Restart",
      },
      {
        "<leader>dx",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
    },
  },
}

return M
