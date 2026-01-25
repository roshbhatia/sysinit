return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    priority = 900,
    dependencies = {
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
    },
  },
}
