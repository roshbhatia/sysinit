-- Two windows holding the two sides of one file's diff, using nvim's own diff. The
-- config already sets `algorithm:histogram`, `linematch:60` and `inline:char`, which is
-- everything a vendored diff library was being carried for.
local M = {}

-- The windows the review reuses, so picking another file refills them rather than
-- stacking a new pair beside them.
local state = { left = nil, right = nil, tab = nil }

--- One side's content, or an empty list when the side does not exist. A file added on the
--- right has no left side, and git answering non-zero is how it says so.
---@param root string
---@param spec string
---@return string[]
local function show(root, spec)
  local res = vim.system({ "git", "-C", root, "show", spec }, { text = true }):wait()
  if res.code ~= 0 then
    return {}
  end
  local lines = vim.split(res.stdout or "", "\n", { plain = true })
  -- git ends the blob with a newline, and splitting that gives a trailing empty line
  -- the file does not have.
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

--- A scratch buffer holding one side, named so the tabline and `:ls` say which side it is.
---@param entry table
---@param spec string
---@return integer buf
local function side_buffer(entry, spec)
  local name = string.format("review://%s/%s", spec, entry.relative)
  -- Reused when the same side is opened again, so stepping back to a file does not
  -- leave a second copy of it behind.
  local existing = vim.fn.bufnr(name)
  if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
    return existing
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, show(entry.root, spec))
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  -- Matched from the real path, so the side is highlighted like the file it came from
  -- rather than as plain text.
  local filetype = vim.filetype.match({ filename = entry.path })
  if filetype then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

--- The buffer for the right side: the real file when the review is of the working tree,
--- and a scratch when it is of something already committed.
---@param entry table
---@return integer buf
local function right_buffer(entry)
  if entry.right ~= nil then
    return side_buffer(entry, entry.right)
  end
  if vim.uv.fs_stat(entry.path) == nil then
    -- Deleted in the working tree, so the right side is empty rather than missing.
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "review://deleted/" .. entry.relative)
    vim.bo[buf].buftype = "nofile"
    return buf
  end
  return vim.fn.bufadd(entry.path)
end

--- Whether the two windows are still standing.
---@return boolean
local function windows_live()
  return state.left ~= nil
    and state.right ~= nil
    and vim.api.nvim_win_is_valid(state.left)
    and vim.api.nvim_win_is_valid(state.right)
end

--- Options both sides carry. Folds off, because a diff read against a list is read by
--- stepping rather than by folding, and a fold column steals the width a sign needs.
---@param win integer
local function apply(win)
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false
  vim.wo[win].foldenable = false
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].signcolumn = "yes:1"
  vim.wo[win].cursorline = true
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

  local left = entry.left and side_buffer(entry, entry.left) or vim.api.nvim_create_buf(false, true)
  local right = right_buffer(entry)

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
    apply(win)
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
  -- Every scratch side, so a second review does not read a stale blob out of a buffer
  -- named for a spec whose content has moved on.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^review://") then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  state = { left = nil, right = nil, tab = nil }
end

return M
