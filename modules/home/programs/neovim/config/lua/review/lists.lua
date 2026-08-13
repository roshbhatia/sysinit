-- The review's spine. Each section is one quickfix list on the stack, so `<` and `>`,
-- which `nvim-bqf` already binds to `:colder` and `:cnewer`, cycle sections, and `[q`
-- and `]q` step files inside one.
local M = {}

-- Every list this review pushed, by id, so a step can tell the review's own lists from
-- whatever else put a list on the stack.
local mine = {}

-- The stack slots the review owns, oldest first, kept across draws and across reviews.
-- The stack holds ten lists, and a review that pushed a fresh set on every refresh would
-- both evict the reader's own lists and leave stale copies of itself behind them.
local owned = {}

--- `+12 -3`, padded so the counts line up down the column. A binary file has no counts.
---@param entry table
---@return string
local function stat(entry)
  if entry.added == nil and entry.removed == nil then
    return entry.status == "N" and "" or "bin"
  end
  return string.format("+%d -%d", entry.added or 0, entry.removed or 0)
end

--- The row's own text: a path, its counts, and its note count.
---@param entry table
---@param width table
---@return string
local function row(entry, width)
  local label = entry.relative
  if entry.from then
    label = entry.from .. " -> " .. entry.relative
  end
  local marks = ""
  if (entry.notes or 0) > 0 then
    marks = string.format("  %d note%s", entry.notes, entry.notes == 1 and "" or "s")
  end
  return string.format(
    "%-" .. width.status .. "s %-" .. width.label .. "s %8s%s",
    entry.status,
    label,
    stat(entry),
    marks
  )
end

--- The widest status and label in a set, so one section's rows align with each other.
---@param entries table[]
---@return table
local function widths(entries)
  local width = { status = 1, label = 10 }
  for _, entry in ipairs(entries) do
    width.status = math.max(width.status, #entry.status)
    local label = entry.from and (entry.from .. " -> " .. entry.relative) or entry.relative
    width.label = math.max(width.label, #label)
  end
  return width
end

--- The quickfix items for one section. An entry with no line still opens, because the
--- review opens it rather than `:cc`.
---@param section table
---@return table[]
local function items(section)
  local width = widths(section.entries)
  local built = {}
  for _, entry in ipairs(section.entries) do
    built[#built + 1] = {
      filename = entry.path,
      lnum = 1,
      col = 1,
      text = row(entry, width),
      user_data = entry,
    }
  end
  return built
end

--- A per-list renderer, because `nvim-pqf` sets the global one and a row of ours comes
--- back from it with the columns gone.
---@param info table
---@return string[]
local function render(info)
  local got = vim.fn.getqflist({ id = info.id, items = 1 }).items
  local lines = {}
  for index = info.start_idx, info.end_idx do
    local item = got[index]
    lines[#lines + 1] = item and item.text or ""
  end
  return lines
end

--- The heading a grouped list draws above a section's files.
---@param section table
---@return table
local function heading(section)
  return {
    text = string.format("%s/  (%d)", section.label, #section.entries),
    valid = 0,
    user_data = { heading = true },
  }
end

--- Whether a slot this review owns is still on the stack.
---@param id integer|nil
---@return boolean
local function alive(id)
  return id ~= nil and vim.fn.getqflist({ id = id, nr = 0 }).nr > 0
end

--- Make one owned list the current one, by id rather than by position, because the stack
--- moves under a list whenever anything else pushes one.
---@param id integer
local function select_list(id)
  local target = vim.fn.getqflist({ id = id, nr = 0 }).nr
  local at = vim.fn.getqflist({ nr = 0 }).nr
  if target == 0 or target == at then
    return
  end
  local delta = target - at
  pcall(vim.cmd, (delta < 0 and "colder " or "cnewer ") .. math.abs(delta))
end

--- Write the built lists into the review's own stack slots, reusing each one, and leave
--- the first current so the spine shows the section whose file the review just opened.
---@param built table[] each `{ title, items, key }`
local function write(built)
  mine = {}
  -- To the newest list first, because pushing one while an older list is current frees
  -- every list above it, and a draw that adds a section would take the ones before it.
  pcall(vim.cmd, "cnewer 99")
  for index, list in ipairs(built) do
    local what = { title = list.title, items = list.items, quickfixtextfunc = render }
    if alive(owned[index]) then
      what.id = owned[index]
      vim.fn.setqflist({}, "r", what)
    else
      vim.fn.setqflist({}, " ", what)
      owned[index] = vim.fn.getqflist({ id = 0 }).id
    end
    mine[owned[index]] = list.key
  end
  -- Empty whatever the last draw owned and this one does not need, so no row of it can
  -- be read back as if it were current.
  for index = #built + 1, #owned do
    if alive(owned[index]) then
      vim.fn.setqflist({}, "r", { id = owned[index], title = "", items = {} })
    end
    owned[index] = nil
  end
  select_list(owned[1])
end

--- Push one list per section, oldest first, so `>` walks them in the order they are
--- declared. An empty section gets no list, because a list with no rows is a dead stop
--- when cycling, and a clean review says so in one list of its own.
---@param sections table[]
---@param said string
function M.push_per_section(sections, said)
  local built = {}
  for _, section in ipairs(sections) do
    if #section.entries > 0 then
      built[#built + 1] = {
        title = string.format("%s: %s", said, section.label),
        items = items(section),
        key = section.key,
      }
    end
  end
  if #built == 0 then
    built[1] = { title = said .. ": clean", items = {}, key = "clean" }
  end
  write(built)
end

--- Push one list holding every section under its own heading, which is what a tree is
--- for: the whole review at once rather than one state of it.
---@param sections table[]
---@param said string
function M.push_grouped(sections, said)
  local built = {}
  for _, section in ipairs(sections) do
    if #section.entries > 0 then
      built[#built + 1] = heading(section)
      local width = widths(section.entries)
      for _, entry in ipairs(section.entries) do
        built[#built + 1] = {
          filename = entry.path,
          lnum = 1,
          col = 1,
          -- Indented under its heading, which is the whole of the tree's structure:
          -- a review has two levels, not many.
          text = "  " .. row(entry, width),
          user_data = entry,
        }
      end
    end
  end
  write({ { title = said, items = built, key = "grouped" } })
end

--- Whether the list on top is one this review pushed.
---@return boolean
function M.is_mine()
  return mine[vim.fn.getqflist({ id = 0 }).id] ~= nil
end

--- The window the list is shown in, if any.
---@return integer|nil
function M.win()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      return win.winid
    end
  end
  return nil
end

--- Show the list, either along the bottom or as a tree down the side.
---@param placement "bottom"|"tree"
function M.show(placement)
  local back = vim.api.nvim_get_current_win()
  pcall(vim.cmd, "cclose")
  if placement == "tree" then
    pcall(vim.cmd, "vertical topleft copen 52")
  else
    pcall(vim.cmd, "botright copen 12")
  end
  if vim.api.nvim_win_is_valid(back) then
    pcall(vim.api.nvim_set_current_win, back)
  end
end

--- The entry under the cursor in the list window, or nil for a heading.
---@return table|nil
function M.entry_under_cursor()
  local win = M.win()
  if win == nil then
    return nil
  end
  local at = vim.api.nvim_win_get_cursor(win)[1]
  local item = vim.fn.getqflist()[at]
  if item == nil or item.user_data == nil or item.user_data.heading then
    return nil
  end
  return item.user_data
end

--- Move the cursor in the list window and answer with the entry it lands on, skipping a
--- heading in the direction of travel so a step never stops on one.
---@param delta integer
---@return table|nil
function M.step(delta)
  local win = M.win()
  if win == nil then
    return nil
  end
  local all = vim.fn.getqflist()
  local at = vim.api.nvim_win_get_cursor(win)[1]
  local row_at = at + delta
  while all[row_at] ~= nil do
    local data = all[row_at].user_data
    if data ~= nil and not data.heading then
      pcall(vim.api.nvim_win_set_cursor, win, { row_at, 0 })
      return data
    end
    row_at = row_at + delta
  end
  return nil
end

--- Empty this review's lists and stop claiming them. The slots are kept, so the next
--- review reuses them rather than growing the stack, and the rows go, because a row of a
--- closed review reads exactly like a row of an open one.
function M.forget()
  mine = {}
  for _, id in ipairs(owned) do
    if alive(id) then
      vim.fn.setqflist({}, "r", { id = id, title = "", items = {} })
    end
  end
end

return M
