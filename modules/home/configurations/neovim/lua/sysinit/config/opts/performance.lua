local M = {}

function M.setup()
  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300

  -- Performance optimizations
  vim.opt.lazyredraw = true
  vim.opt.synmaxcol = 240
  vim.opt.swapfile = false
  vim.opt.writebackup = false
  vim.opt.backup = false

  -- Optimize for large files
  vim.api.nvim_create_autocmd("BufReadPre", {
    callback = function()
      local file_size = vim.fn.getfsize(vim.fn.expand("%:p"))
      if file_size > 1024 * 1024 then -- 1MB
        vim.opt_local.synmaxcol = 80
        vim.opt_local.lazyredraw = true
      end
    end,
  })

  -- Garbage collection tuning
  local gc_interval = 1000
  local function set_gc()
    vim.defer_fn(function()
      collectgarbage("collect")
      set_gc()
    end, gc_interval)
  end
  set_gc()
end

return M
