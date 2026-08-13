-- The buffers a review reads a file's two sides out of. Shared by both layouts, so the
-- side-by-side and the inline views read the same blob for the same entry.
local M = {}

--- One side's content, or an empty list when the side does not exist. A file added on the
--- right has no left side, and git answering non-zero is how it says so.
---@param root string
---@param spec string
---@return string[]
function M.lines(root, spec)
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
function M.side(entry, spec)
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
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.lines(entry.root, spec))
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
function M.right(entry)
  if entry.right ~= nil then
    return M.side(entry, entry.right)
  end
  if vim.uv.fs_stat(entry.path) == nil then
    -- Deleted in the working tree, so the right side is empty rather than missing.
    local name = "review://deleted/" .. entry.relative
    local existing = vim.fn.bufnr(name)
    if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
      return existing
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    vim.bo[buf].buftype = "nofile"
    return buf
  end
  return vim.fn.bufadd(entry.path)
end

--- The left side's lines, for a layout that reads them rather than showing them.
---@param entry table
---@return string[]
function M.left_lines(entry)
  if entry.left == nil then
    return {}
  end
  return M.lines(entry.root, entry.left)
end

--- Options a review window carries. Folds off, because a diff read against a list is read
--- by stepping rather than by folding, and a fold column steals the width a sign needs.
---@param win integer
function M.apply(win)
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false
  vim.wo[win].foldenable = false
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].signcolumn = "yes:1"
  vim.wo[win].cursorline = true
end

--- Delete every scratch side, so a second review does not read a stale blob out of a
--- buffer named for a spec whose content has moved on.
function M.wipe()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("^review://") then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

return M
