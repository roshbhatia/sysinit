local M = {}

local refresh_timer = nil

function M.setup(config)
  config = config or {}
  local refresh_config = config.file_refresh or {}

  if not refresh_config.enable then
    return
  end

  local augroup = vim.api.nvim_create_augroup("AITerminalFileRefresh", { clear = true })

  vim.api.nvim_create_autocmd({
    "CursorHold",
    "CursorHoldI",
    "FocusGained",
    "BufEnter",
    "InsertLeave",
    "TextChanged",
  }, {
    group = augroup,
    pattern = "*",
    callback = function()
      if vim.fn.filereadable(vim.fn.expand("%")) == 1 then
        vim.cmd("checktime")
      end
    end,
  })

  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end

  refresh_timer = vim.loop.new_timer()
  if refresh_timer then
    refresh_timer:start(
      0,
      refresh_config.timer_interval or 1000,
      vim.schedule_wrap(function()
        vim.cmd("silent! checktime")
      end)
    )
  end

  if refresh_config.show_notifications then
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = augroup,
      pattern = "*",
      callback = function()
        vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
      end,
    })
  end

  if refresh_config.updatetime then
    vim.o.updatetime = refresh_config.updatetime
  end
end

function M.cleanup()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

return M
