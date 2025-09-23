local M = {}

function M.get_git_diff(state)
  local bufnr = state.buf
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return "No file path available"
  end
  local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)
  if output == "" then
    vim.notify("No git diff available for " .. filepath, vim.log.levels.WARN)
    return "No git diff available"
  end
  return output
end

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

function M.open_native_diff(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end

  local temp_file = vim.fn.tempname()
  local cmd = string.format(
    "git show HEAD:%s > %s",
    vim.fn.shellescape(filepath),
    vim.fn.shellescape(temp_file)
  )
  local result = vim.fn.system(cmd)
  if result ~= "" then
    vim.notify("Failed to retrieve git HEAD version for " .. filepath, vim.log.levels.WARN)
    vim.fn.delete(temp_file)
    return "Failed to retrieve git HEAD version"
  end

  vim.cmd("vsplit " .. temp_file)
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(new_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe")
  vim.cmd("diffthis")
  vim.cmd("wincmd p")
  vim.cmd("diffthis")

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = new_buf,
    callback = function()
      vim.fn.delete(temp_file)
    end,
    once = true,
  })

  return "Native diff view opened"
end

function M.open_diff_view(state)
  local has_diffview, _ = pcall(require, "diffview")
  if has_diffview then
    local filepath = vim.api.nvim_buf_get_name(state.buf)
    if filepath == "" then
      return "No file path available"
    end
    vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(filepath))
    return "Diffview opened"
  else
    return M.open_native_diff(state)
  end
end

return M
