-- Fallback theme configuration when not Nix-managed
local M = {}

function M.setup()
  -- Only run if NOT Nix-managed
  if vim.g.nix_hm_managed then
    return
  end

  -- Fallback to base16 default when not Nix-managed
  -- The base16-nvim plugin will handle the colorscheme
end

return M
