
local M = {}

local function pane_alive(pane_id, callback)
  vim.fn.jobstart({ "wezterm", "cli", "list", "--format", "json" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local raw = table.concat(data or {}, "\n")
      local ok, panes = pcall(vim.json.decode, raw)
      if not ok or type(panes) ~= "table" then
        callback(false)
        return
      end
      for _, p in ipairs(panes) do
        if p.pane_id == pane_id then
          callback(true)
          return
        end
      end
      callback(false)
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        callback(false)
      end
    end,
  })
end

local function activate_pane(pane_id)
  vim.fn.jobstart({ "wezterm", "cli", "activate-pane", "--pane-id", tostring(pane_id) }, { detach = true })
end

local function kill_pane(pane_id)
  vim.fn.jobstart({ "wezterm", "cli", "kill-pane", "--pane-id", tostring(pane_id) }, { detach = true })
end

local function build_env_prefix(env_table)
  local parts = {}
  for k, v in pairs(env_table or {}) do
    parts[#parts + 1] = string.format("export %s=%s;", k, vim.fn.shellescape(tostring(v)))
  end
  return table.concat(parts, " ")
end

local EDITOR_WRAPPER = [[#!/bin/sh
if [ -z "$NVIM_HOST_SOCKET" ] || ! command -v nvim >/dev/null 2>&1; then
  exec nvim "$@"
fi
ctl=$(mktemp) || exec nvim "$@"
sentinel=$(mktemp) && rm -f "$sentinel"
printf '%s\n%s\n' "$1" "$sentinel" >"$ctl"
[ -n "$NVIM_HOST_PANE" ] && wezterm cli activate-pane --pane-id "$NVIM_HOST_PANE" >/dev/null 2>&1
nvim --server "$NVIM_HOST_SOCKET" --remote-expr "luaeval('require(\"utils.remote_editor\").open(_A)', '$ctl')" >/dev/null 2>&1
while [ ! -e "$sentinel" ]; do sleep 0.15; done
rm -f "$ctl" "$sentinel"
[ -n "$WEZTERM_PANE" ] && wezterm cli activate-pane --pane-id "$WEZTERM_PANE" >/dev/null 2>&1
]]

local function editor_wrapper_path()
  local path = vim.fn.stdpath("cache") .. "/agent-remote-editor.sh"
  if vim.fn.filereadable(path) == 0 or table.concat(vim.fn.readfile(path), "\n") .. "\n" ~= EDITOR_WRAPPER then
    local ok = pcall(vim.fn.writefile, vim.split(EDITOR_WRAPPER, "\n", { plain = true }), path)
    if not ok then
      return nil
    end
    vim.fn.setfperm(path, "rwxr-xr-x")
  end
  return path
end

local function editor_env(parent_pane_id)
  local sock = vim.v.servername
  if not sock or sock == "" then
    return {}
  end
  local script = editor_wrapper_path()
  if not script then
    return {}
  end
  return {
    EDITOR = script,
    VISUAL = script,
    NVIM_HOST_SOCKET = sock,
    NVIM_HOST_PANE = tostring(parent_pane_id),
  }
end

---@param parent_pane_id integer
---@param name string  used in error messages and vim.g tracking key
---@param cmd_string string
---@param opts { env?: table, percent?: number, side?: "left"|"right" }
---@param focus boolean
---@return integer|nil  spawned pane_id, or nil on failure
local function _spawn(parent_pane_id, name, cmd_string, opts, focus)
  local env = vim.tbl_extend("force", editor_env(parent_pane_id), opts.env or {})
  local env_str = build_env_prefix(env)
  local full_cmd = env_str ~= "" and (env_str .. " " .. cmd_string) or cmd_string
  local pct = math.floor((opts.percent or 0.4) * 100)
  local side_flag = (opts.side == "left") and "--left" or "--right"
  local cwd = vim.fn.getcwd()

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d %s --percent %d --cwd %s -- sh -c %s 2>/dev/null",
    parent_pane_id,
    side_flag,
    pct,
    vim.fn.shellescape(cwd),
    vim.fn.shellescape(full_cmd)
  )

  local result = vim.fn.system(spawn_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify(("%s/wezterm: spawn failed (exit %d)"):format(name, vim.v.shell_error), vim.log.levels.ERROR)
    return nil
  end

  local id = tonumber(vim.trim(result))
  if not id then
    vim.notify(("%s/wezterm: could not parse pane id"):format(name), vim.log.levels.ERROR)
    return nil
  end

  vim.g["harness_wezterm_pane_" .. name] = id

  if focus then
    vim.defer_fn(function()
      activate_pane(id)
    end, 80)
  end

  return id
end

---@param pane_id integer
---@return boolean
function M.pane_alive_sync(pane_id)
  local res = vim.fn.system({ "wezterm", "cli", "list", "--format", "json" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  local ok, panes = pcall(vim.json.decode, res)
  if not ok or type(panes) ~= "table" then
    return false
  end
  for _, p in ipairs(panes) do
    if p.pane_id == pane_id then
      return true
    end
  end
  return false
end

---@param pane_id integer
---@param text string
---@param submit boolean  append \r to submit
---@return boolean
function M.send_text(pane_id, text, submit)
  local payload = submit and (text .. "\r") or text
  local tmp = vim.fn.tempname()
  local ok = pcall(vim.fn.writefile, vim.split(payload, "\n", { plain = true }), tmp, "b")
  if not ok then
    return false
  end
  vim.fn.system(string.format("wezterm cli send-text --no-paste --pane-id %d < %s", pane_id, vim.fn.shellescape(tmp)))
  local sent = vim.v.shell_error == 0
  pcall(vim.fn.delete, tmp)
  if sent then
    vim.fn.jobstart({ "wezterm", "cli", "activate-pane", "--pane-id", tostring(pane_id) }, { detach = true })
  end
  return sent
end

--- @param opts? { name?: string, percent?: number, side?: "left"|"right" }
--- @return table provider
function M.build_provider(opts)
  opts = opts or {}
  local name = opts.name or "agent"

  local Provider = {}
  local pane_id = nil
  local parent_pane_id = tonumber(vim.env.WEZTERM_PANE)
  local cfg = {}

  local function spawn(cmd_string, env_table, effective_config, focus)
    if not parent_pane_id then
      vim.notify(("%s/wezterm: WEZTERM_PANE not set; cannot split"):format(name), vim.log.levels.ERROR)
      return
    end
    local merged = vim.tbl_extend("force", cfg, effective_config or {})
    local id = _spawn(parent_pane_id, name, cmd_string, {
      env = env_table,
      percent = opts.percent or merged.split_width_percentage,
      side = opts.side or merged.split_side,
    }, focus)
    if id then
      pane_id = id
    end
  end

  function Provider.setup(term_config)
    cfg = term_config or {}
  end

  function Provider.is_available()
    return parent_pane_id ~= nil and vim.fn.executable("wezterm") == 1
  end

  function Provider.open(cmd_string, env_table, effective_config, focus)
    if pane_id then
      pane_alive(pane_id, function(alive)
        if alive then
          if focus then
            activate_pane(pane_id)
          end
        else
          pane_id = nil
          spawn(cmd_string, env_table, effective_config, focus)
        end
      end)
      return
    end
    spawn(cmd_string, env_table, effective_config, focus)
  end

  function Provider.close()
    if pane_id then
      kill_pane(pane_id)
      vim.g["harness_wezterm_pane_" .. name] = nil
      pane_id = nil
    end
  end

  function Provider.simple_toggle(cmd_string, env_table, effective_config)
    if pane_id then
      pane_alive(pane_id, function(alive)
        if alive then
          Provider.close()
        else
          pane_id = nil
          spawn(cmd_string, env_table, effective_config, true)
        end
      end)
    else
      spawn(cmd_string, env_table, effective_config, true)
    end
  end

  function Provider.focus_toggle(cmd_string, env_table, effective_config)
    if pane_id then
      pane_alive(pane_id, function(alive)
        if alive then
          activate_pane(pane_id)
        else
          pane_id = nil
          spawn(cmd_string, env_table, effective_config, true)
        end
      end)
    else
      spawn(cmd_string, env_table, effective_config, true)
    end
  end

  Provider.toggle = Provider.simple_toggle

  function Provider.get_active_bufnr()
    return nil
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("wezterm_terminal_" .. name, { clear = true }),
    callback = function()
      if pane_id then
        kill_pane(pane_id)
      end
    end,
  })

  return Provider
end

--- @param cmd string  shell command to run in the pane (e.g. "opencode --port")
--- @param opts? { name?: string, percent?: number, side?: "left"|"right", env?: table<string,string> }
--- @return { start: fun(), stop: fun(), toggle: fun() }
function M.build_server_callbacks(cmd, opts)
  opts = opts or {}
  local name = opts.name or "server"
  local pane_id = nil
  local parent_pane_id = tonumber(vim.env.WEZTERM_PANE)

  local function do_spawn(focus)
    if not parent_pane_id then
      vim.notify(("%s/wezterm: WEZTERM_PANE not set; cannot split"):format(name), vim.log.levels.ERROR)
      return
    end
    local id = _spawn(parent_pane_id, name, cmd, opts, focus)
    if id then
      pane_id = id
    end
  end

  local function start()
    if pane_id then
      pane_alive(pane_id, function(alive)
        if alive then
          activate_pane(pane_id)
        else
          pane_id = nil
          do_spawn(true)
        end
      end)
    else
      do_spawn(true)
    end
  end

  local function stop()
    if pane_id then
      kill_pane(pane_id)
      vim.g["harness_wezterm_pane_" .. name] = nil
      pane_id = nil
    end
  end

  local function toggle()
    if pane_id then
      pane_alive(pane_id, function(alive)
        if alive then
          activate_pane(pane_id)
        else
          pane_id = nil
          do_spawn(true)
        end
      end)
    else
      do_spawn(true)
    end
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("wezterm_terminal_" .. name, { clear = true }),
    callback = function()
      if pane_id then
        kill_pane(pane_id)
      end
    end,
  })

  return { start = start, stop = stop, toggle = toggle }
end

return M
