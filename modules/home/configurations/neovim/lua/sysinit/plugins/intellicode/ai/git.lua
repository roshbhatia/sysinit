local M = {}
function M.populate_qflist_with_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff --no-color %s", vim.fn.shellescape(filepath))
  local output = vim.fn.systemlist(cmd)
  if output == nil or #output == 0 then
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end

  local qf_entries = {}
  local current_file = filepath
  local lnum = 0
  for _, line in ipairs(output) do
    if line:match("^@@") then
      local new_lnum = line:match("^@@ %-%d+,%d+ %+(%d+),")
      if new_lnum then
        lnum = tonumber(new_lnum) - 1
      end
    elseif line:match("^%+") and not line:match("^%+%+%+") then
      lnum = lnum + 1
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = line:sub(2),
        type = "I",
      })
    elseif line:match("^%-") and not line:match("^%-%-%-") then
      table.insert(qf_entries, {
        filename = current_file,
        lnum = lnum,
        text = "Removed: " .. line:sub(2),
        type = "W",
      })
    end
  end

  if #qf_entries > 0 then
    vim.fn.setqflist(qf_entries, "r")
    return "Quickfix list populated with diff changes"
  else
    vim.notify("No diff changes to populate for " .. filepath, vim.log.levels.WARN)
    return "No diff changes to populate"
  end
end

return M
