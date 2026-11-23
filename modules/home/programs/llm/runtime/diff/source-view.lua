local function jump(position)
  local attempts = 0

  local function find_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buf) == position.file then
        local line = math.min(position.line, vim.api.nvim_buf_line_count(buf))
        vim.api.nvim_win_set_cursor(win, { line, position.column - 1 })
        return
      end
    end

    attempts = attempts + 1
    if attempts < 20 then
      vim.defer_fn(find_window, 50)
    end
  end

  find_window()
  return true
end

if vim.env.SYSINIT_DIFFVIEW_ARGS then
  local args = vim.json.decode(vim.env.SYSINIT_DIFFVIEW_ARGS)
  vim.env.SYSINIT_DIFFVIEW_ARGS = nil
  require("diffview").open(args)
end

return { jump = jump }
