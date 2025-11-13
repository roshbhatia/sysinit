local M = {}

function M.setup()
  local function is_valid_buffer(buf)
    -- Check if buffer is valid and loaded
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return false
    end

    -- Check if buffer is listed
    if not vim.bo[buf].buflisted then
      return false
    end

    -- Exclude special buffer types
    local buftype = vim.bo[buf].buftype
    if buftype ~= "" and buftype ~= "acwrite" then
      -- Exclude: terminal, quickfix, help, nofile, prompt, etc.
      return false
    end

    -- Exclude buffers with no name (scratch buffers)
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname == "" then
      return false
    end

    return true
  end

  local function get_loaded_listed_bufs()
    local bufs = vim.tbl_filter(is_valid_buffer, vim.api.nvim_list_bufs())

    -- Sort buffers by last used time (most recent first)
    local buf_info = {}
    for _, buf in ipairs(bufs) do
      local ok, info = pcall(vim.fn.getbufinfo, buf)
      if ok and info and info[1] then
        buf_info[buf] = info[1].lastused or 0
      else
        buf_info[buf] = 0
      end
    end

    table.sort(bufs, function(a, b)
      return buf_info[a] > buf_info[b]
    end)

    return bufs
  end

  local function goto_buffer(offset)
    local bufs = get_loaded_listed_bufs()
    if #bufs < 2 then
      vim.notify("No other buffers available", vim.log.levels.INFO)
      return
    end

    local current = vim.api.nvim_get_current_buf()
    local idx = nil
    for i, buf in ipairs(bufs) do
      if buf == current then
        idx = i
        break
      end
    end

    if not idx then
      -- Current buffer not in list, go to most recent
      idx = 0
    end

    local target_idx = ((idx - 1 + offset) % #bufs) + 1
    local target = bufs[target_idx]

    if not target or target == current then
      return
    end

    -- Validate target buffer before switching
    if not vim.api.nvim_buf_is_valid(target) then
      vim.notify("Target buffer is invalid", vim.log.levels.WARN)
      return
    end

    local ok, err = pcall(vim.api.nvim_set_current_buf, target)
    if not ok then
      vim.notify("Failed to switch buffer: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  vim.keymap.set("n", "<leader>bn", function()
    goto_buffer(1)
  end, {
    noremap = true,
    silent = true,
    desc = "Buffer next",
  })

  vim.keymap.set("n", "<leader>bp", function()
    goto_buffer(-1)
  end, {
    noremap = true,
    silent = true,
    desc = "Buffer previous",
  })
end

return M
