local M = {}

function M.setup()
  local function get_loaded_listed_bufs()
    return vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
  end

  local function goto_buffer(offset)
    local bufs = get_loaded_listed_bufs()
    if #bufs < 2 then
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
      return
    end
    local target = bufs[((idx - 1 + offset) % #bufs) + 1]
    if target and target ~= current then
      vim.api.nvim_set_current_buf(target)
    end
  end

  vim.keymap.set("n", "<leader>bn", function()
    goto_buffer(1)
  end, {
    noremap = true,
    silent = true,
    desc = "Next loaded buffer",
  })

  vim.keymap.set("n", "<leader>bp", function()
    goto_buffer(-1)
  end, {
    noremap = true,
    silent = true,
    desc = "Previous loaded buffer",
  })
end

return M
