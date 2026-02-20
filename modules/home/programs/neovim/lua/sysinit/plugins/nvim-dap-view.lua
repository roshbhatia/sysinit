return {
  {
    "igorlfs/nvim-dap-view",
    opts = {},
    keys = function()
      return {
        {
          "<leader>rr",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle DAP View",
        },
      }
    end,
  },
}
