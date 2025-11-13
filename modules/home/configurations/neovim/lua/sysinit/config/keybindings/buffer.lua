local M = {}

function M.setup()
  local prev_buf = nil

  vim.api.nvim_create_autocmd("BufLeave", {
    callback = function()
      local cur = vim.api.nvim_get_current_buf()
      -- Only remember real file buffers
      if
        vim.bo[cur].buflisted
        and vim.bo[cur].buftype == ""
        and vim.api.nvim_buf_get_name(cur) ~= ""
      then
        prev_buf = cur
      end
    end,
  })

  local function goto_previous()
    local cur = vim.api.nvim_get_current_buf()
    if
      not prev_buf
      or prev_buf == cur
      or not vim.api.nvim_buf_is_valid(prev_buf)
      or not vim.bo[prev_buf].buflisted
    then
      return
    end
    vim.api.nvim_set_current_buf(prev_buf)
  end

  local function get_mru_buffers()
    local seen = {}
    local bufs = {}

    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if
        not seen[b]
        and vim.api.nvim_buf_is_valid(b)
        and vim.bo[b].buflisted
        and vim.bo[b].buftype == ""
        and vim.api.nvim_buf_get_name(b) ~= ""
      then
        seen[b] = true
        table.insert(bufs, b)
      end
    end

    table.sort(bufs, function(a, b)
      return (vim.fn.getbufinfo(a)[1].lastused or 0) > (vim.fn.getbufinfo(b)[1].lastused or 0)
    end)
    return bufs
  end

  local function goto_next_mru()
    local cur = vim.api.nvim_get_current_buf()
    local bufs = get_mru_buffers()

    for i, b in ipairs(bufs) do
      if b == cur then
        local next_i = (i % #bufs) + 1
        local target = bufs[next_i]
        if target and vim.api.nvim_buf_is_valid(target) then
          vim.api.nvim_set_current_buf(target)
        end
        return
      end
    end
  end

  vim.keymap.set("n", "<leader>bp", goto_previous, { desc = "Buffer: previous" })
  vim.keymap.set("n", "<leader>bn", goto_next_mru, { desc = "Buffer: next" })
end

return M
