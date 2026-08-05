return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = function()
      local neoconf = require("neoconf")
      local defaults = {
        complete_function_calls = true,
        expose_as_code_action = "all",
        code_lens = "all",
      }
      return vim.tbl_deep_extend("force", defaults, neoconf.get("typescript_tools") or {})
    end,
    ft = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },
  },
}
