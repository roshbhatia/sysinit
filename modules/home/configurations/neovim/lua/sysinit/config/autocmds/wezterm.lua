-- modules/home/configurations/neovim/lua/sysinit/config/autocmds/wezterm.lua
-- Signals WezTerm when entering/exiting nvim for better pane management

local M = {}

function M.setup()
  -- Signal WezTerm that we're in nvim when entering
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local ok = pcall(function()
        vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "true"')
      end)
      if not ok then
        vim.notify("Warning: Could not signal WezTerm", vim.log.levels.WARN)
      end
    end,
  })

  -- Signal WezTerm when leaving nvim
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      pcall(function()
        vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "false"')
      end)
    end,
  })
end

return M
