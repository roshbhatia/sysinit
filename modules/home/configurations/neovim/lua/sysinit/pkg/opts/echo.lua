local M = {}

function M.setup()
  local original_echo = vim.api.nvim_echo
  vim.api.nvim_echo = function(chunks, history, opts)
    if history and #chunks > 0 then
      local msg = table.concat(
        vim.tbl_map(function(chunk)
          return chunk[1]
        end, chunks),
        ""
      )
      vim.notify(msg)
    else
      original_echo(chunks, history, opts)
    end
  end
end

return M
