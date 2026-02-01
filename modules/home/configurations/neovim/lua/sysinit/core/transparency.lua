-- Transparency settings (optional override for stylix)
local M = {}

function M.apply()
  local transparency_enabled = vim.g.nix_hm_managed and true or false

  if transparency_enabled then
    -- Additional transparency overrides not covered by stylix
    vim.cmd.highlight({ "NormalFloat", "guibg=NONE", "ctermbg=NONE" })
    vim.cmd.highlight({ "FloatBorder", "guibg=NONE", "ctermbg=NONE" })
  end
end

return M
