return {
  {
    "mason-org/mason.nvim",
    enabled = not vim.g.nix_managed,
    opts = {},
    cmd = "Mason",
  },
}
