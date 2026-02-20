return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    end,
    keys = {
      {
        "<leader>rb",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>rc",
        function()
          require("dap").continue()
        end,
        desc = "Continue/Start",
      },
      {
        "<leader>rt",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>rB",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear breakpoints",
      },
      {
        "<leader>rR",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>rs",
        function()
          require("dap").restart()
        end,
        desc = "Restart",
      },
      {
        "<leader>rx",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>ri",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>ro",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
    },
  },
}
