-- modules/home/configurations/neovim/lua/sysinit/config/autocmds/nvim-rpc.lua
-- Manages neovim RPC socket for MCP server integration

local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup("NvimRPC", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
      -- Get WezTerm pane ID from environment
      local wezterm_pane = vim.env.WEZTERM_PANE

      if not wezterm_pane then
        vim.notify("Warning: WEZTERM_PANE not set. MCP neovim server integration may not work.", vim.log.levels.WARN)
        return
      end

      -- Create unique socket path based on WezTerm pane ID
      local socket_path = string.format("/tmp/nvim-%s.sock", wezterm_pane)

      -- Check if socket already exists and remove it
      if vim.fn.filereadable(socket_path) == 1 or vim.fn.isdirectory(socket_path) == 1 then
        vim.fn.delete(socket_path)
      end

      -- Start RPC server on the socket
      vim.fn.serverstart(socket_path)

      -- Export socket path to environment for child processes
      vim.env.NVIM_SOCKET_PATH = socket_path
    end,
  })

  -- Clean up socket on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      local socket_path = vim.env.NVIM_SOCKET_PATH
      if socket_path and vim.fn.filereadable(socket_path) == 1 then
        vim.fn.delete(socket_path)
      end
    end,
  })
end

return M
