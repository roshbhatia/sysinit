local M = {}

local state = { win = nil, buf = nil, path = nil, pane = nil, snacks = nil }

local AUGROUP = vim.api.nvim_create_augroup("SysinitPreview", { clear = true })

local function win_valid()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function have_glow()
  return vim.fn.executable("glow") == 1
end

---@return integer|nil  the pane nvim itself runs in
local function host_pane()
  local parent = tonumber(vim.env.WEZTERM_PANE)
  if not parent or vim.fn.executable("wezterm") ~= 1 then
    return nil
  end
  return parent
end

local function snacks()
  local ok, mod = pcall(require, "snacks")
  return ok and mod or nil
end

---@param full string
---@return string
local function render_cmd(full)
  return ("clear; CLICOLOR_FORCE=1 glow --style auto --width $(tput cols) %s"):format(vim.fn.shellescape(full))
end

local function pane_alive(pane)
  if not pane then
    return false
  end
  local wezterm = require("utils.wezterm_terminal")
  return wezterm.pane_alive_sync(pane)
end

---@param full string
---@return boolean handled
local function render_in_wezterm(full)
  local parent = host_pane()
  if not parent then
    return false
  end
  local wezterm = require("utils.wezterm_terminal")

  if pane_alive(state.pane) then
    return wezterm.send_text(state.pane, render_cmd(full), true)
  end

  local cmd = ("%s; exec ${SHELL:-sh}"):format(render_cmd(full))
  local spawn = ("wezterm cli split-pane --pane-id %d --right --percent 42 -- sh -c %s 2>/dev/null"):format(
    parent,
    vim.fn.shellescape(cmd)
  )
  local out = vim.fn.system(spawn)
  if vim.v.shell_error ~= 0 then
    return false
  end
  local id = tonumber(vim.trim(out))
  if not id then
    return false
  end
  state.pane = id
  vim.fn.jobstart({ "wezterm", "cli", "activate-pane", "--pane-id", tostring(parent) }, { detach = true })
  return true
end

local START_SCREENS = {
  snacks_dashboard = true,
  dashboard = true,
  alpha = true,
  starter = true,
  ministarter = true,
}

local function dismiss_start_screen()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if START_SCREENS[vim.bo[buf].filetype] then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

local function open_window()
  if win_valid() then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  dismiss_start_screen()
  vim.cmd("botright vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(state.win, math.max(60, math.floor(vim.o.columns * 0.42)))
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].winfixwidth = true
end

---@param full string
---@return boolean handled
local function render_in_snacks(full)
  local mod = snacks()
  if not mod or not mod.terminal then
    return false
  end
  if state.snacks and state.snacks:valid() then
    pcall(function()
      state.snacks:close()
    end)
  end
  local ok, win = pcall(mod.terminal.open, render_cmd(full) .. "; exec ${SHELL:-sh}", {
    win = { position = "right", width = 0.42 },
    auto_close = false,
    start_insert = false,
  })
  if not ok or not win then
    return false
  end
  state.snacks = win
  return true
end

local function render_with_glow(full)
  local old = state.buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.win, buf)
  vim.bo[buf].bufhidden = "wipe"
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(full, ":t"))
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, nowait = true })

  local chan = vim.api.nvim_open_term(buf, {})
  local width = math.max(40, vim.api.nvim_win_get_width(state.win) - 2)
  vim.system(
    { "glow", "--style", "auto", "--width", tostring(width), full },
    { env = { CLICOLOR_FORCE = "1" } },
    vim.schedule_wrap(function(res)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local out = (res.stdout or ""):gsub("\n", "\r\n")
      pcall(vim.api.nvim_chan_send, chan, out)
    end)
  )

  state.buf = buf
  if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end
end

local function watch(full)
  vim.api.nvim_clear_autocmds({ group = AUGROUP })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = AUGROUP,
    pattern = full,
    callback = function()
      M.refresh()
    end,
  })
end

---@param path string
function M.open(path, opts)
  opts = opts or {}
  local full = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  if vim.fn.filereadable(full) == 0 then
    return { ok = false, error = "no such file: " .. full }
  end
  state.path = full
  watch(full)

  if have_glow() then
    if render_in_wezterm(full) then
      return { ok = true, path = full, renderer = "glow", surface = "wezterm" }
    end
    if render_in_snacks(full) then
      return { ok = true, path = full, renderer = "glow", surface = "snacks" }
    end
  end

  local prev = vim.api.nvim_get_current_win()
  open_window()

  local renderer
  if have_glow() then
    render_with_glow(full)
    renderer = "glow"
  else
    vim.cmd("edit " .. vim.fn.fnameescape(full))
    state.buf = vim.api.nvim_get_current_buf()
    renderer = "buffer"
  end

  if opts.focus == false and vim.api.nvim_win_is_valid(prev) then
    vim.api.nvim_set_current_win(prev)
  end
  return { ok = true, path = full, renderer = renderer, surface = "split" }
end

function M.refresh()
  if not state.path then
    return
  end
  if not (pane_alive(state.pane) or (state.snacks and state.snacks:valid()) or win_valid()) then
    return
  end
  M.open(state.path, { focus = false })
end

function M.close()
  vim.api.nvim_clear_autocmds({ group = AUGROUP })
  if pane_alive(state.pane) then
    vim.fn.jobstart({ "wezterm", "cli", "kill-pane", "--pane-id", tostring(state.pane) }, { detach = true })
  end
  if state.snacks and state.snacks:valid() then
    pcall(function()
      state.snacks:close()
    end)
  end
  if win_valid() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win, state.buf, state.path, state.pane, state.snacks = nil, nil, nil, nil, nil
end

function M.is_open()
  return pane_alive(state.pane) or (state.snacks ~= nil and state.snacks:valid()) or win_valid()
end

---@return string|nil  path currently shown, if any
function M.current()
  return M.is_open() and state.path or nil
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = AUGROUP,
  callback = function()
    if pane_alive(state.pane) then
      vim.fn.system({ "wezterm", "cli", "kill-pane", "--pane-id", tostring(state.pane) })
    end
  end,
})

return M
