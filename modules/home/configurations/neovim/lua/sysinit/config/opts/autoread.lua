local M = {}

function M.setup()
  vim.opt.shortmess:append("A")
  vim.opt.autoread = true

  local function check_file_changes()
    if vim.fn.mode() == "c" then
      return
    end

    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local filetype = vim.bo[buf].filetype

    if buftype ~= "" or filetype == "help" then
      return
    end

    local before = vim.fn.getftime(vim.api.nvim_buf_get_name(buf))
    vim.cmd("checktime")
    local after = vim.fn.getftime(vim.api.nvim_buf_get_name(buf))

    if after ~= -1 and before ~= after then
      vim.schedule(function()
        vim.notify(
          ("File reloaded: %s"):format(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")),
          vim.log.levels.INFO,
          { title = "Auto Reload" }
        )
      end)
    end
  end

  local events = { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }
  vim.api.nvim_create_autocmd(events, {
    pattern = "*",
    callback = check_file_changes,
  })

  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = "*",
    callback = function(ev)
      if ev.match and vim.fn.filereadable(ev.match) == 1 then
        vim.schedule(function()
          vim.notify(
            ("External change detected: %s"):format(vim.fn.fnamemodify(ev.match, ":~:.")),
            vim.log.levels.WARN,
            { title = "Auto Reload" }
          )
        end)
      end
    end,
  })
end

return M
