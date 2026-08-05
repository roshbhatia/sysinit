return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPost",
    dependencies = {
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
      "Chaitanyabsprip/fastaction.nvim",
    },
  },
}
