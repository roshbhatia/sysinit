local M = {}

local config = {}
local terminals = {}
local active_terminal = nil
local augroup = nil

function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  if not augroup then
    augroup = vim.api.nvim_create_augroup("AIManager", { clear = true })

    vim.api.nvim_create_autocmd("BufWipeout", {
      group = augroup,
      callback = function(ev)
        local termname = vim.b[ev.buf].ai_terminal_name
        if termname and terminals[termname] then
          terminals[termname] = nil
        end
      end,
    })

    vim.api.nvim_create_autocmd("BufHidden", {
      group = augroup,
      callback = function(ev)
        local termname = vim.b[ev.buf].ai_terminal_name
        if termname and terminals[termname] then
          terminals[termname].visible = false
        end
      end,
    })

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = augroup,
      callback = function(ev)
        local termname = vim.b[ev.buf].ai_terminal_name
        if termname and terminals[termname] then
          terminals[termname].visible = true
        end
      end,
    })

    vim.api.nvim_create_autocmd("TermOpen", {
      group = augroup,
      callback = function(ev)
        for name, term_data in pairs(terminals) do
          if term_data.term and term_data.term.buf == ev.buf then
            vim.b[ev.buf].ai_terminal_name = name
            vim.b[ev.buf].ai_terminal_cmd = term_data.cmd
            break
          end
        end
      end,
    })
  end
end

function M.open(termname)
  local agent_config = config.terminals[termname]
  if not agent_config then
    vim.notify(string.format("Unknown terminal: %s. Check ai_manager.setup() config", termname), vim.log.levels.ERROR)
    return
  end

  if terminals[termname] then
    local term_data = terminals[termname]
    if term_data.term and term_data.term.buf and vim.api.nvim_buf_is_valid(term_data.term.buf) then
      term_data.term:show()
      term_data.visible = true
      return
    else
      terminals[termname] = nil
    end
  end

  local term = Snacks.terminal.toggle(agent_config.cmd, {
    win = {
      position = "right",
      width = 0.5,
    },
    env = config.env,
    bo = {
      filetype = "snacks_terminal",
    },
  })

  terminals[termname] = {
    term = term,
    cmd = agent_config.cmd,
    visible = true,
  }

  if term and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    vim.b[term.buf].ai_terminal_name = termname
    vim.b[term.buf].ai_terminal_cmd = agent_config.cmd
  end

  active_terminal = termname
end

function M.toggle(termname)
  local term_data = terminals[termname]

  if not term_data then
    M.open(termname)
    return
  end

  if term_data.term and term_data.term.buf and vim.api.nvim_buf_is_valid(term_data.term.buf) then
    term_data.term:toggle()
    term_data.visible = not term_data.visible
  else
    terminals[termname] = nil
    M.open(termname)
  end
end

function M.focus(termname)
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Use open() first", termname), vim.log.levels.WARN)
    return
  end

  if not term_data.visible then
    M.open(termname)
  end

  if term_data.term.win and vim.api.nvim_win_is_valid(term_data.term.win) then
    vim.api.nvim_set_current_win(term_data.term.win)
  else
    if term_data.term.buf and vim.api.nvim_buf_is_valid(term_data.term.buf) then
      term_data.term:show()
      term_data.visible = true
      if term_data.term.win and vim.api.nvim_win_is_valid(term_data.term.win) then
        vim.api.nvim_set_current_win(term_data.term.win)
      end
    end
  end
end

function M.send(termname, text, opts)
  opts = opts or {}
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Open it first", termname), vim.log.levels.ERROR)
    return
  end

  if not term_data.visible then
    M.open(termname)
  end

  if not term_data.term.buf or not vim.api.nvim_buf_is_valid(term_data.term.buf) then
    vim.notify(string.format("Terminal buffer invalid: %s", termname), vim.log.levels.ERROR)
    return
  end

  if not term_data.term.job_id then
    vim.notify(string.format("Terminal job not found: %s", termname), vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.api.nvim_chan_send, term_data.term.job_id, text)
  if not ok then
    vim.notify(string.format("Failed to send text to %s: %s", termname, err), vim.log.levels.ERROR)
    return
  end

  if opts.submit then
    vim.api.nvim_chan_send(term_data.term.job_id, "\n")
  end
end

function M.get_info(termname)
  local term_data = terminals[termname]

  if not term_data then
    return nil
  end

  return {
    name = termname,
    visible = term_data.visible,
    buf = term_data.term.buf,
    win = term_data.term.win,
    cmd = term_data.cmd,
  }
end

function M.get_all()
  local result = {}
  for name, _ in pairs(terminals) do
    result[name] = M.get_info(name)
  end
  return result
end

function M.exists(termname)
  local term_data = terminals[termname]
  if not term_data then
    return false
  end
  return term_data.term.buf and vim.api.nvim_buf_is_valid(term_data.term.buf)
end

function M.get_active()
  return active_terminal
end

function M.set_active(termname)
  if terminals[termname] then
    active_terminal = termname
  end
end

function M.activate(termname)
  local term_data = terminals[termname]

  if not term_data then
    M.open(termname)
  else
    if term_data.visible then
      M.focus(termname)
    else
      M.toggle(termname)
    end
    active_terminal = termname
  end
end

function M.send_to_active(text, opts)
  if not active_terminal then
    vim.notify("No active AI terminal", vim.log.levels.WARN)
    return
  end
  M.send(active_terminal, text, opts)
end

function M.ensure_active_and_send(text)
  if not active_terminal then
    vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
    return
  end

  local term_info = M.get_info(active_terminal)
  if not term_info or not term_info.visible then
    M.open(active_terminal)
    M.focus(active_terminal)

    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 300)
  else
    M.focus(active_terminal)
    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 300)
  end
end

return M
