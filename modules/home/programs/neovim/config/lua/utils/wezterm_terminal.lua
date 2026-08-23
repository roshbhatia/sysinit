-- The five wezterm pane calls this config makes, in one place.
local M = {}

---@param args string[]
---@return string|nil stdout, string|nil err
function M.cli(args)
  -- --no-auto-start because a wezterm cli call with no GUI attached starts a
  -- headless mux server and draws the pane nowhere.
  local cmd = { "wezterm", "cli", "--no-auto-start" }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or "wezterm cli failed")
  end
  return vim.trim(result.stdout or ""), nil
end

---@param pane_id string|integer
---@return boolean
function M.pane_alive(pane_id)
  local out = M.cli({ "list", "--format", "json" })
  if not out or out == "" then
    return false
  end
  local ok, panes = pcall(vim.json.decode, out)
  if not ok or type(panes) ~= "table" then
    return false
  end
  for _, pane in ipairs(panes) do
    if tostring(pane.pane_id) == tostring(pane_id) then
      return true
    end
  end
  return false
end

---@param opts { parent?: string|integer, cwd?: string, percent?: integer, side?: "left"|"right", argv: string[] }
---@return string|nil pane_id, string|nil err
function M.split(opts)
  local args = { "split-pane", opts.side == "left" and "--left" or "--right" }
  if opts.parent then
    vim.list_extend(args, { "--pane-id", tostring(opts.parent) })
  end
  vim.list_extend(args, { "--percent", tostring(opts.percent or 40) })
  if opts.cwd then
    vim.list_extend(args, { "--cwd", opts.cwd })
  end
  vim.list_extend(args, { "--" })
  vim.list_extend(args, opts.argv)
  return M.cli(args)
end

-- paste defaults true, so a multi-line prompt reaches an agent as one block. A
-- shell command wants paste = false, or bracketed paste markers reach the shell.
---@param pane_id string|integer
---@param text string
---@param opts? { submit?: boolean, paste?: boolean }
---@return boolean
function M.send_text(pane_id, text, opts)
  opts = opts or {}
  local args = { "send-text", "--pane-id", tostring(pane_id) }
  if opts.paste == false then
    table.insert(args, "--no-paste")
  end
  local payload = opts.submit and (text .. "\r") or text

  local cmd = { "wezterm", "cli", "--no-auto-start" }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { stdin = payload }):wait()
  if result.code ~= 0 then
    return false
  end
  M.activate(pane_id)
  return true
end

---@param pane_id string|integer
function M.activate(pane_id)
  M.cli({ "activate-pane", "--pane-id", tostring(pane_id) })
end

---@param pane_id string|integer
function M.kill(pane_id)
  M.cli({ "kill-pane", "--pane-id", tostring(pane_id) })
end

return M
