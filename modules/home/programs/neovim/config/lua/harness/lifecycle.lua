local M = {}

local function pick_backend()
  local in_wezterm = vim.env.WEZTERM_PANE ~= nil and vim.fn.executable("wezterm") == 1
  return in_wezterm and "wezterm" or "snacks"
end

---@param cmd string  shell command to run in the pane
function M.build(cmd, opts)
  opts = opts or {}
  local name = opts.name or "harness"
  local backend = pick_backend()

  if backend == "wezterm" then
    return M._wezterm(cmd, opts, name)
  end
  return M._snacks(cmd, opts, name)
end

local wt = require("utils.wezterm_terminal")

---@private
function M._wezterm(cmd, opts, name)
  local server = wt.build_server_callbacks(cmd, {
    name = name,
    percent = opts.percent or 0.4,
    side = opts.side,
    env = opts.env,
  })

  local function get_pane()
    local pid = vim.g["harness_wezterm_pane_" .. name]
    if pid and wt.pane_alive_sync(pid) then
      return pid
    end
    return nil
  end

  return {
    toggle = server.toggle,
    focus = server.start,
    kill = function()
      server.stop()
    end,
    is_visible = function()
      return get_pane() ~= nil
    end,
    send = function(text, send_opts)
      send_opts = send_opts or {}
      local submit = send_opts.submit ~= false
      local pid = get_pane()
      if pid then
        wt.send_text(pid, text, submit)
        return
      end
      server.start()
      vim.defer_fn(function()
        local p = get_pane()
        if p then
          wt.send_text(p, text, submit)
        else
          vim.notify(name .. ": wezterm pane not found after start", vim.log.levels.WARN)
        end
      end, 400)
    end,
  }
end

local function snacks_mod()
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.terminal then
    return nil
  end
  return snacks
end

local function snacks_opts(opts)
  return {
    win = {
      position = opts.side == "left" and "left" or "right",
      width = opts.percent or 0.4,
    },
    env = opts.env,
  }
end

---@private
function M._snacks(cmd, opts, name)
  local function get_term(create)
    local snacks = snacks_mod()
    if not snacks then
      return nil
    end
    return snacks.terminal.get(cmd, vim.tbl_extend("force", snacks_opts(opts), { create = create ~= false }))
  end

  return {
    toggle = function()
      local snacks = snacks_mod()
      if not snacks then
        vim.notify(name .. ": snacks.terminal unavailable", vim.log.levels.ERROR)
        return
      end
      snacks.terminal.toggle(cmd, snacks_opts(opts))
    end,
    focus = function()
      local snacks = snacks_mod()
      if not snacks then
        return
      end
      snacks.terminal.focus(cmd, snacks_opts(opts))
    end,
    kill = function()
      local term = get_term(false)
      if term then
        pcall(function()
          term:close()
        end)
      end
    end,
    is_visible = function()
      local term = get_term(false)
      if not term then
        return false
      end
      local ok, valid = pcall(function()
        return term:buf_valid() and term.win and vim.api.nvim_win_is_valid(term.win)
      end)
      return ok and valid
    end,
    send = function(text, send_opts)
      send_opts = send_opts or {}
      local term = get_term(true)
      if not term or not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
        vim.notify(name .. ": snacks terminal buf invalid", vim.log.levels.WARN)
        return
      end
      local chan = vim.b[term.buf].terminal_job_id
      if not chan then
        vim.notify(name .. ": terminal_job_id missing on snacks buf", vim.log.levels.WARN)
        return
      end
      local payload = (send_opts.submit ~= false) and (text .. "\r") or text
      pcall(vim.api.nvim_chan_send, chan, payload)
      pcall(function()
        if term.win and vim.api.nvim_win_is_valid(term.win) then
          vim.api.nvim_set_current_win(term.win)
          vim.cmd("startinsert")
        end
      end)
    end,
  }
end

return M
