return {
  {
    "docker/nvim-dap-docker",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    ft = { "dockerfile" },
    config = function()
      require("dap-docker").setup()
    end,
  },
}
