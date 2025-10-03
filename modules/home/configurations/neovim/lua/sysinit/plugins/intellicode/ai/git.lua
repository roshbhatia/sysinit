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

function M.open_diff_view(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return "No file path available"
  end
  vim.cmd("MiniDiffToggle " .. vim.fn.fnameescape(filepath))
  return "MiniDiff opened"
end

-- Get current git branch
function M.get_git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null")
  if not handle then
    return ""
  end
  local branch = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()
  return branch
end

-- Get git status for current file
function M.get_file_git_status(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return ""
  end
  
  local cmd = string.format("git status --porcelain %s 2>/dev/null", vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)
  
  if output == "" then
    return "No changes"
  end
  
  return output:gsub("^%s*(.-)%s*$", "%1")
end

-- Get recent git commits for current file
function M.get_file_git_log(state)
  local filepath = vim.api.nvim_buf_get_name(state.buf)
  if filepath == "" then
    return ""
  end
  
  local cmd = string.format(
    "git log -5 --oneline --no-decorate %s 2>/dev/null",
    vim.fn.shellescape(filepath)
  )
  local output = vim.fn.system(cmd)
  
  if output == "" then
    return "No git history"
  end
  
  return output:gsub("^%s*(.-)%s*$", "%1")
end

-- Get unstaged changes summary
function M.get_git_status_summary()
  local cmd = "git status --short 2>/dev/null"
  local output = vim.fn.system(cmd)
  
  if output == "" then
    return "No changes"
  end
  
  return output:gsub("^%s*(.-)%s*$", "%1")
end

return M
