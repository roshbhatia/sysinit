return {
  {
    "mason-org/mason.nvim",
    -- Only install on systems without nix.
    enabled = not vim.fn.executable("nix") == 1,
    opts = {},
  },
}
