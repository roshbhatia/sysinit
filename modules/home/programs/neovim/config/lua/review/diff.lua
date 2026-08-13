-- Two windows holding the two sides of one file's diff, using nvim's own diff. The
-- config already sets `algorithm:histogram`, `linematch:60` and `inline:char`, which is
-- everything a vendored diff library was being carried for.
local M = {}

local buffers = require("review.buffers")

-- The windows the review reuses, so picking another file refills them rather than
-- stacking a new pair beside them.
local state = { left = nil, right = nil, tab = nil }

--- Whether the two windows are still standing.
---@return boolean
local function windows_live()
  return state.left ~= nil
    and state.right ~= nil
    and vim.api.nvim_win_is_valid(state.left)
    and vim.api.nvim_win_is_valid(state.right)
end

--- Build the pair of windows in the current tab, left of the current window.
local function build()
  vim.cmd("enew")
  state.left = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  state.right = vim.api.nvim_get_current_win()
  state.tab = vim.api.nvim_get_current_tabpage()
end

--- Show one entry in the two windows, building them when they are not standing.
---@param entry table
---@return boolean opened
function M.open(entry)
  if not windows_live() then
    build()
  end

  local left = entry.left and buffers.side(entry, entry.left) or vim.api.nvim_create_buf(false, true)
  local right = buffers.right(entry)

  -- Diff mode off first: setting a buffer into a window that is already in diff mode
  -- leaves the old buffer diffed against the new one.
  for _, win in ipairs({ state.left, state.right }) do
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffoff")
    end)
  end

  vim.api.nvim_win_set_buf(state.left, left)
  vim.api.nvim_win_set_buf(state.right, right)

  for _, win in ipairs({ state.left, state.right }) do
    buffers.apply(win)
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffthis")
    end)
  end

  -- The cursor lands on the first change rather than on line one, which is what a
  -- reader opening a diff wants to see.
  vim.api.nvim_set_current_win(state.right)
  vim.api.nvim_win_set_cursor(state.right, { 1, 0 })
  pcall(vim.cmd, "normal! ]c")
  return true
end

--- Whether a diff pair is open.
---@return boolean
function M.is_open()
  return windows_live()
end

--- The window holding the side a reader edits.
---@return integer|nil
function M.current_win()
  return windows_live() and state.right or nil
end

--- Tear the pair down, leaving the tab to the caller.
function M.close()
  for _, win in ipairs({ state.left, state.right }) do
    if win ~= nil and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        vim.cmd("diffoff")
      end)
    end
  end
  -- The left window goes, so a layout change does not leave half a pair behind. The
  -- right one stays, because the next layout shows the same file in it.
  if state.left ~= nil and vim.api.nvim_win_is_valid(state.left) and windows_live() then
    pcall(vim.api.nvim_win_close, state.left, true)
  end
  buffers.wipe()
  state = { left = nil, right = nil, tab = nil }
end

return M
