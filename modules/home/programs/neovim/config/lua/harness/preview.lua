-- Markdown preview for spec artifacts.
--
-- glow emits ANSI, so the rendered form goes into a terminal buffer where the
-- escapes actually mean something. Without glow we fall back to the plain
-- markdown buffer, which is still readable and keeps this dependency optional.
--
-- One reusable window on the right; agent panes own the left now.

local M = {}

local state = { win = nil, buf = nil, path = nil }

local function win_valid()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function have_glow()
  return vim.fn.executable("glow") == 1
end

local function open_window()
  if win_valid() then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  -- Required lazily: control.lua reaches back into this module for its
  -- preview op, and a top-level require either way would be a cycle.
  require("harness.control").dismiss_start_screen()
  vim.cmd("botright vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(state.win, math.max(60, math.floor(vim.o.columns * 0.42)))
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].winfixwidth = true
end

local function render_with_glow(full)
  local old = state.buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.win, buf)
  vim.bo[buf].bufhidden = "wipe"
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(full, ":t"))
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, nowait = true })

  -- nvim_open_term interprets glow's ANSI without running the job *in* the
  -- buffer. Spawning it with jobstart({term=true}) would leave a
  -- "[Process exited 0]" line and a term:// buffer name in the winbar.
  local chan = vim.api.nvim_open_term(buf, {})
  local width = math.max(40, vim.api.nvim_win_get_width(state.win) - 2)
  vim.system(
    { "glow", "--style", "auto", "--width", tostring(width), full },
    -- glow strips color when stdout is a pipe, which is exactly what we want
    -- to override: the escapes are the point.
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

--- Open `path` in the preview window.
---@param path string
---@param opts? { focus?: boolean }
---@return table result
function M.open(path, opts)
  opts = opts or {}
  local full = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  if vim.fn.filereadable(full) == 0 then
    return { ok = false, error = "no such file: " .. full }
  end

  local prev = vim.api.nvim_get_current_win()
  open_window()
  state.path = full

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
  return { ok = true, path = full, renderer = renderer }
end

--- Re-render whatever is already showing. Used by the spec watcher.
function M.refresh()
  if not state.path or not win_valid() then
    return
  end
  M.open(state.path, { focus = false })
end

function M.close()
  if win_valid() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win, state.buf, state.path = nil, nil, nil
end

function M.is_open()
  return win_valid()
end

---@return string|nil  path currently shown, if any
function M.current()
  return win_valid() and state.path or nil
end

return M
