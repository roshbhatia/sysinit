local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>bn", function()
    local bufs = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    if #bufs > 1 then
      vim.cmd("bnext")
    end
  end, {
    noremap = true,
    silent = true,
    desc = "Next buffer",
  })

  vim.keymap.set("n", "<leader>bp", function()
    local bufs = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    if #bufs > 1 then
      vim.cmd("bprevious")
    end
  end, {
    noremap = true,
    silent = true,
    desc = "Previous buffer",
  })

  vim.keymap.set("n", "<leader>bc", function()
    local current = vim.api.nvim_get_current_buf()
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
      if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" or vim.bo[buf].buftype ~= "" then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end
    vim.cmd("silent SessionSave")
  end, {
    noremap = true,
    silent = true,
    desc = "Close unlisted buffers",
  })
end

return M

