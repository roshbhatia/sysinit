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
end

return M

