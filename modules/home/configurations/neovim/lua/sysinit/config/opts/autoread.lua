local M = {}

function M.setup()
  vim.opt.shortmess:append("A")
  vim.opt.autoread = true

  local state = {
    last_mtime = {},
    debounce = nil,
    pending = false,
    last_msg = {},
  }

  local function should_notify(key, interval)
    local now = (vim.uv or vim.loop).now()
    local prev = state.last_msg[key] or 0
    if now - prev < interval then
      return false
    end
    state.last_msg[key] = now
    return true
  end

  local function stat_mtime(path)
    if path == "" then
      return -1
    end
    local s = (vim.uv or vim.loop).fs_stat(path)
    if not s then
      return -1
    end
    return s.mtime.sec
  end

  local function reload_buffer(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return
    end
    if not vim.bo[buf].modified then
      -- safe to force reload silently
      vim.cmd("silent! checktime")
      state.last_mtime[buf] = stat_mtime(name)
      if should_notify("reload:" .. name, 2000) then
        vim.notify(
          ("File reloaded: %s"):format(vim.fn.fnamemodify(name, ":~:.")),
          vim.log.levels.INFO,
          { title = "Auto Reload" }
        )
      end
    else
      if should_notify("conflict:" .. name, 5000) then
        vim.notify(
          ("External change detected but buffer has unsaved changes: %s"):format(
            vim.fn.fnamemodify(name, ":~:.")
          ),
          vim.log.levels.WARN,
          { title = "Auto Reload" }
        )
      end
    end
  end

  local function check_file_changes()
    if state.pending then
      return
    end
    state.pending = true
    if state.debounce then
      state.debounce:stop()
      state.debounce:close()
    end
    state.debounce = (vim.uv or vim.loop).new_timer()
    state.debounce:start(300, 0, function()
      vim.schedule(function()
        state.pending = false
        local buf = vim.api.nvim_get_current_buf()
        if not buf or not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        if vim.fn.mode() == "c" then
          return
        end
        local bt = vim.bo[buf].buftype
        local ft = vim.bo[buf].filetype
        if bt ~= "" or ft == "help" then
          return
        end
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" then
          return
        end
        local current_mtime = stat_mtime(name)
        local last = state.last_mtime[buf]
        if last == nil then
          state.last_mtime[buf] = current_mtime
          return
        end
        if current_mtime ~= -1 and last ~= current_mtime then
          reload_buffer(buf)
        end
      end)
    end)
  end

  local events = { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }
  vim.api.nvim_create_autocmd(events, {
    pattern = "*",
    callback = check_file_changes,
  })

  -- Handle external file changes reported by shell
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    pattern = "*",
    callback = function(ev)
      if ev.match and vim.fn.filereadable(ev.match) == 1 then
        local buf = vim.api.nvim_get_current_buf()
        reload_buffer(buf)
      end
    end,
  })

  -- Auto accept swap file by choosing to open current file (avoid blocking prompt)
  vim.api.nvim_create_autocmd("SwapExists", {
    pattern = "*",
    callback = function()
      vim.v.swapchoice = "o" -- open anyway
      if should_notify("swap:" .. vim.v.swapname, 10000) then
        vim.notify(
          ("Swap file found, opening current version: %s"):format(
            vim.fn.fnamemodify(vim.v.swapname or "", ":t")
          ),
          vim.log.levels.INFO,
          { title = "Auto Reload" }
        )
      end
    end,
  })
end

return M
