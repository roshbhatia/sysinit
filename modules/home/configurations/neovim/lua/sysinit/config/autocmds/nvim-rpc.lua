-- modules/home/configurations/neovim/lua/sysinit/config/autocmds/nvim-rpc.lua
-- Manages neovim RPC socket for MCP server integration
-- Fixed: Added socket validation and proper error handling

local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup("NvimRPC", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
      -- Get WezTerm pane ID from environment
      local wezterm_pane = vim.env.WEZTERM_PANE

      if not wezterm_pane then
        vim.notify(
          "Warning: WEZTERM_PANE not set. Running outside WezTerm. MCP integration limited.",
          vim.log.levels.WARN
        )
        return
      end

      -- Create unique socket path based on WezTerm pane ID
      local socket_path = string.format("/tmp/nvim-%s.sock", wezterm_pane)

      -- Check if socket already exists and remove it
      if vim.fn.filereadable(socket_path) == 1 or vim.fn.isdirectory(socket_path) == 1 then
        local ok = pcall(function()
          vim.fn.delete(socket_path)
        end)
        if not ok then
          vim.notify(string.format("Warning: Could not remove stale socket at %s", socket_path), vim.log.levels.WARN)
        end
      end

      -- Start RPC server on the socket
      local result = vim.fn.serverstart(socket_path)
      if not result or result == "" then
        vim.notify(string.format("ERROR: Failed to start RPC server on %s", socket_path), vim.log.levels.ERROR)
        return
      end

      -- Validate socket was created
      if vim.fn.filereadable(socket_path) ~= 1 then
        vim.notify(string.format("ERROR: RPC socket created but not found at %s", socket_path), vim.log.levels.ERROR)
        return
      end

      -- Export socket path to environment for child processes
      vim.env.NVIM_SOCKET_PATH = socket_path
      vim.notify(string.format("RPC socket ready at %s (pane %s)", socket_path, wezterm_pane), vim.log.levels.INFO)
    end,
  })

  -- Clean up socket on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      local socket_path = vim.env.NVIM_SOCKET_PATH
      if socket_path then
        local ok = pcall(function()
          if vim.fn.filereadable(socket_path) == 1 then
            vim.fn.delete(socket_path)
          end
        end)
        if not ok then
          vim.notify(string.format("Warning: Could not clean up socket at %s", socket_path), vim.log.levels.WARN)
        end
      end
    end,
  })
end

return M
