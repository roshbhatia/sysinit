return {
  {
    "igorlfs/nvim-dap-view",
    opts = {},
    keys = function()
      return {
        {
          "<leader>cee",
          function()
            vim.cmd("DapViewToggle")
          end,
          desc = "Toggle DAP View",
        },
      }
    end,
  },
}
