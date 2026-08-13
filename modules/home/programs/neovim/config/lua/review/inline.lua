-- One window holding the file as it is now, with what was removed drawn above the line it
-- was removed from. `vim.diff` gives the hunks, so this needs no diff library of its own.
local M = {}

local buffers = require("review.buffers")

local ns = vim.api.nvim_create_namespace("review_inline")

-- The one window the inline layout reuses.
local state = { win = nil, buf = nil }

--- The text `vim.diff` wants: newline-terminated, and empty for a side with no lines,
--- because concatenating nothing still gives one empty line.
---@param lines string[]
---@return string
local function text(lines)
  if #lines == 0 then
    return ""
  end
  return table.concat(lines, "\n") .. "\n"
end

--- Draw one hunk: the removed lines as virtual lines, and the added ones highlighted.
---@param buf integer
---@param before string[]
---@param hunk integer[] `{ start_a, count_a, start_b, count_b }`
local function draw(buf, before, hunk)
  local start_a, count_a, start_b, count_b = hunk[1], hunk[2], hunk[3], hunk[4]

  if count_a > 0 then
    local virt = {}
    for at = start_a, start_a + count_a - 1 do
      virt[#virt + 1] = { { before[at] or "", "DiffDelete" } }
    end
    -- A hunk that also adds draws above the first added line. A pure deletion has no
    -- line of its own, and `start_b` is the line it was taken from after, so it draws
    -- below that one, or above line one when it was taken from the top.
    local row, above
    if count_b > 0 then
      row, above = start_b - 1, true
    elseif start_b == 0 then
      row, above = 0, true
    else
      row, above = start_b - 1, false
    end
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, math.max(row, 0), 0, {
      virt_lines = virt,
      virt_lines_above = above,
    })
  end

  for row = start_b, start_b + count_b - 1 do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, row - 1, 0, {
      line_hl_group = count_a > 0 and "DiffText" or "DiffAdd",
    })
  end
end

--- Whether the window is still standing.
---@return boolean
local function window_live()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- Show one entry in one window, marking it up against its left side.
---@param entry table
---@return boolean opened
function M.open(entry)
  if not window_live() then
    vim.cmd("enew")
    state.win = vim.api.nvim_get_current_win()
  end

  local buf = buffers.right(entry)
  vim.api.nvim_win_set_buf(state.win, buf)
  buffers.apply(state.win)
  -- Diff mode off, because the same window may have been half of the split layout, and a
  -- window left in diff mode folds and colours the file behind these marks.
  vim.api.nvim_win_call(state.win, function()
    vim.cmd("diffoff")
  end)
  state.buf = buf

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local before = buffers.left_lines(entry)
  local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local hunks = vim.diff(text(before), text(after), {
    result_type = "indices",
    algorithm = "histogram",
    linematch = 60,
  })
  for _, hunk in ipairs(hunks or {}) do
    draw(buf, before, hunk)
  end

  -- On the first change, which is where the split layout also lands.
  vim.api.nvim_set_current_win(state.win)
  local first = (hunks or {})[1]
  local row = first and math.max(first[3], 1) or 1
  pcall(vim.api.nvim_win_set_cursor, state.win, { math.min(row, vim.api.nvim_buf_line_count(buf)), 0 })
  return true
end

--- Whether the inline layout is showing.
---@return boolean
function M.is_open()
  return window_live()
end

--- The window the reader is in.
---@return integer|nil
function M.current_win()
  return window_live() and state.win or nil
end

--- Clear the marks, leaving the window to the caller: the other layout reuses it.
function M.close()
  if state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  end
  buffers.wipe()
  state = { win = nil, buf = nil }
end

return M
