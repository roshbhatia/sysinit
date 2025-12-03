local M = {}

local config = {}
local terminals = {}
local active_terminal = nil
local augroup = nil

local function pane_exists(pane_id)
  if not pane_id then
    return false
  end

  -- Check if pane still exists via wezterm CLI
  local result = vim.fn.system(string.format("wezterm cli list --format json 2>/dev/null"))

  if vim.v.shell_error ~= 0 then
    return false
  end

  local ok, panes = pcall(vim.fn.json_decode, result)
  if not ok or not panes then
    return false
  end

  for _, pane in ipairs(panes) do
    if pane.pane_id == pane_id then
      return true
    end
  end

  return false
end

function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  if not augroup then
    augroup = vim.api.nvim_create_augroup("AIManager", { clear = true })

    -- Periodically clean up closed panes
    vim.api.nvim_create_autocmd("CursorHold", {
      group = augroup,
      callback = function()
        for name, term_data in pairs(terminals) do
          if term_data.pane_id and not pane_exists(term_data.pane_id) then
            terminals[name] = nil
            if active_terminal == name then
              active_terminal = nil
            end
          end
        end
      end,
    })

    -- Close all AI panes when neovim exits
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        for _, term_data in pairs(terminals) do
          if term_data.pane_id then
            vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", term_data.pane_id))
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

  -- Check if pane already exists
  if terminals[termname] and pane_exists(terminals[termname].pane_id) then
    -- Just activate it
    M.focus(termname)
    return
  end

  local agents = require("sysinit.plugins.intellicode.agents")
  local agent = agents.get_by_name(termname)
  local cwd = vim.fn.getcwd()

  -- Build env vars string
  local env_str = ""
  for key, value in pairs(config.env) do
    env_str = env_str .. string.format("export %s=%s; ", key, vim.fn.shellescape(value))
  end

  -- Spawn new pane on the right with 50% width
  local spawn_cmd = string.format(
    "wezterm cli split-pane --right --percent 50 --cwd %s -- sh -c %s 2>&1",
    vim.fn.shellescape(cwd),
    vim.fn.shellescape(env_str .. agent_config.cmd)
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error == 0 then
    local pane_id = tonumber(vim.trim(result))

    if pane_id then
      terminals[termname] = {
        pane_id = pane_id,
        cmd = agent_config.cmd,
        cwd = cwd,
        visible = true,
      }
      active_terminal = termname

      -- Set pane title if agent info available
      if agent then
        vim.defer_fn(function()
          vim.fn.system(string.format("wezterm cli set-tab-title --pane-id %d %s 2>/dev/null", pane_id, vim.fn.shellescape(string.format("%s %s", agent.icon, agent.label))))
        end, 100)
      end
    else
      vim.notify("Failed to parse pane ID: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("Failed to spawn pane: " .. result, vim.log.levels.ERROR)
  end
end

function M.toggle(termname)
  local term_data = terminals[termname]

  if term_data and pane_exists(term_data.pane_id) then
    M.focus(termname)
  else
    M.open(termname)
  end
end

function M.focus(termname)
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Use open() first", termname), vim.log.levels.WARN)
    return
  end

  if not pane_exists(term_data.pane_id) then
    vim.notify(string.format("Pane no longer exists for %s. Reopening...", termname), vim.log.levels.WARN)
    terminals[termname] = nil
    M.open(termname)
    return
  end

  -- Activate the pane
  vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d 2>/dev/null", term_data.pane_id))
  active_terminal = termname
end

function M.send(termname, text, opts)
  opts = opts or {}
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Open it first", termname), vim.log.levels.ERROR)
    return
  end

  if not pane_exists(term_data.pane_id) then
    vim.notify(string.format("Pane no longer exists for %s", termname), vim.log.levels.ERROR)
    return
  end

  -- Send text to the pane
  local send_cmd = string.format("wezterm cli send-text --pane-id %d --no-paste %s 2>/dev/null", term_data.pane_id, vim.fn.shellescape(text))
  vim.fn.system(send_cmd)

  -- Submit if requested
  if opts.submit then
    vim.fn.system(string.format("wezterm cli send-text --pane-id %d $'\\n' 2>/dev/null", term_data.pane_id))
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
    pane_id = term_data.pane_id,
    cmd = term_data.cmd,
    cwd = term_data.cwd,
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
  return pane_exists(term_data.pane_id)
end

function M.close(termname)
  local term_data = terminals[termname]

  if term_data and term_data.pane_id then
    vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", term_data.pane_id))
    terminals[termname] = nil
    if active_terminal == termname then
      active_terminal = nil
    end
  end
end

function M.cleanup_terminal(termname)
  terminals[termname] = nil
  if active_terminal == termname then
    active_terminal = nil
  end
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
    if pane_exists(term_data.pane_id) then
      M.focus(termname)
    else
      M.open(termname)
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
  if not term_info or not pane_exists(term_info.pane_id) then
    M.open(active_terminal)
    M.focus(active_terminal)

    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 300)
  else
    M.focus(active_terminal)
    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 100)
  end
end

return M
