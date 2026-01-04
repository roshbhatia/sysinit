local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup("NvimRPC", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    callback = function()
      local wezterm_pane = vim.env.WEZTERM_PANE

      if not wezterm_pane then
        vim.notify(
          "Warning: WEZTERM_PANE not set. Running outside WezTerm. MCP integration limited.",
          vim.log.levels.WARN
        )
        return
      end

      local socket_path = string.format("/tmp/nvim-%s.sock", wezterm_pane)

      if vim.fn.filereadable(socket_path) == 1 or vim.fn.isdirectory(socket_path) == 1 then
        local ok = pcall(function()
          vim.fn.delete(socket_path)
        end)
        if not ok then
          vim.notify(string.format("Warning: Could not remove stale socket at %s", socket_path), vim.log.levels.WARN)
        end
      end

      local result = vim.fn.serverstart(socket_path)
      if not result or result == "" then
        vim.notify(string.format("ERROR: Failed to start RPC server on %s", socket_path), vim.log.levels.ERROR)
        return
      end

      if vim.fn.filereadable(socket_path) ~= 1 then
        vim.notify(string.format("ERROR: RPC socket created but not found at %s", socket_path), vim.log.levels.ERROR)
        return
      end

      vim.env.NVIM_SOCKET_PATH = socket_path
    end,
  })

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
