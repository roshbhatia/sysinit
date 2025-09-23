local M = {}

function M.request(method, params, timeout)
  local ok, result = pcall(vim.lsp.buf_request_sync, 0, method, params, timeout or 500)
  if not ok or not result then
    return nil
  end
  for _, res in pairs(result) do
    if res.result then
      return res.result
    end
  end
  return nil
end

return M
