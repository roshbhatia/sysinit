return {
  {
    "RRethy/base16-nvim",
    -- Only load if NOT Nix-managed (stylix handles it when Nix-managed)
    enabled = not vim.g.nix_hm_managed,
    lazy = false,
    priority = 1000,
    config = function()
      -- Set a default base16 colorscheme when not Nix-managed
      vim.cmd.colorscheme("base16-default-dark")
    end,
  },
}
