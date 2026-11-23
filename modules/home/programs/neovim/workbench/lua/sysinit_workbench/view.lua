local M = {}

function M.buffer(title, filetype)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, title .. "/" .. buffer)
  vim.bo[buffer].filetype = filetype
  vim.bo[buffer].bufhidden = "wipe"
  vim.cmd.tabnew()
  vim.api.nvim_set_current_buf(buffer)
  return buffer
end

function M.render(buffer, lines)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
end

function M.query(argv, cwd, callback)
  vim.system(
    argv,
    { cwd = cwd, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        callback(
          vim.trim(result.stderr or "") ~= "" and vim.trim(result.stderr) or argv[1] .. " failed"
        )
        return
      end
      callback(nil, result.stdout)
    end)
  )
end

function M.open_file(root, relative, line)
  local path = vim.uv.fs_realpath(vim.fs.joinpath(root, relative))
  if not path or path:sub(1, #root + 1) ~= root .. "/" then
    vim.notify("File is unavailable in the selected checkout: " .. relative, vim.log.levels.WARN)
    return
  end
  vim.cmd.vsplit({ args = { path } })
  vim.api.nvim_win_set_cursor(
    0,
    { math.min(math.max(1, line or 1), vim.api.nvim_buf_line_count(0)), 0 }
  )
end

return M
