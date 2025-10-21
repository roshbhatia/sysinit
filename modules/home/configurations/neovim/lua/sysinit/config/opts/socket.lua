-- Socket configuration for agent-hooks integration
local M = {}

function M.setup()
  -- Set up a predictable server name for socket communication
  -- This creates a socket at /tmp/nvim_sysinit (or similar)
  -- that agent hooks can discover and connect to
  if vim.fn.has("nvim-0.5") == 1 then
    -- Start the RPC server with a predictable socket name
    -- If running from terminal, preserve the existing socket
    if not vim.env.NVIM then
      local socket_path = vim.fn.expand("/tmp/nvim_sysinit")

      -- Only set if not already listening
      if vim.v.servername == "" or vim.v.servername == vim.v.progname then
        vim.fn.serverstart(socket_path)
      end

      -- Export the socket path for child processes
      vim.env.NVIM = vim.v.servername
    end
  end
end

return M
