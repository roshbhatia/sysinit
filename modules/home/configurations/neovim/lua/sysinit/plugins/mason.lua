return {
  {
    "mason-org/mason.nvim",
    -- Only enable if NOT Nix/home-manager managed
    enabled = not vim.g.nix_hm_managed,
    opts = {},
  },
}
