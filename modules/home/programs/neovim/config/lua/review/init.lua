-- A review: one repository, one base, and the sections its changes fall into. It lives in
-- a tab of its own, so closing it is closing that tab and nothing else goes with it.
local M = {}

local lists = require("review.lists")
local diff = require("review.diff")
local inline = require("review.inline")

---@class ReviewState
---@field tab integer|nil
---@field root string|nil
---@field base string|nil a commit the working tree is compared back to
---@field rev table|nil a revision under review, as `{ sha, parent, short }`
---@field sections table[]
---@field entry table|nil the file being read, so a layout change can redraw it
---@field placement "bottom"|"tree"
---@field layout "split"|"inline"
local state = {
  tab = nil,
  root = nil,
  base = nil,
  rev = nil,
  sections = {},
  entry = nil,
  -- Remembered across reviews, so the next one opens the way the last was left.
  placement = "bottom",
  layout = "split",
}

--- Show one file in whichever layout is chosen, tearing the other one down first.
---@param entry table
---@return boolean opened
local function render(entry)
  state.entry = entry
  if state.layout == "inline" then
    diff.close()
    return inline.open(entry)
  end
  inline.close()
  return diff.open(entry)
end

--- Whether the review's tab is still standing.
---@return boolean
function M.is_open()
  return state.tab ~= nil and vim.api.nvim_tabpage_is_valid(state.tab)
end

--- What the review is of, for a title and a message.
---@return string
local function said()
  local name = state.root and vim.fn.fnamemodify(state.root, ":t") or "review"
  if state.rev then
    return string.format("%s %s", name, state.rev.short)
  end
  if state.base then
    return string.format("%s since %s", name, state.base)
  end
  return name
end

--- Draw the sections into the spine and open the first file.
local function draw()
  if state.placement == "tree" then
    lists.push_grouped(state.sections, said())
  else
    lists.push_per_section(state.sections, said())
  end
  lists.show(state.placement)

  local first = nil
  for _, section in ipairs(state.sections) do
    if #section.entries > 0 then
      first = section.entries[1]
      break
    end
  end
  if first then
    render(first)
  end

  local counts = {}
  for _, section in ipairs(state.sections) do
    if section.failed then
      vim.notify(string.format("Review: %s: %s", section.label, section.failed), vim.log.levels.WARN)
    end
    if #section.entries > 0 then
      counts[#counts + 1] = string.format("%d %s", #section.entries, section.label)
    end
  end
  if #counts == 0 then
    vim.notify("Review: " .. said() .. " is clean", vim.log.levels.INFO)
  else
    vim.notify("Review: " .. said() .. " has " .. table.concat(counts, ", "), vim.log.levels.INFO)
  end
end

--- Build the tab the review lives in.
local function open_tab()
  vim.cmd("tabnew")
  state.tab = vim.api.nvim_get_current_tabpage()
  vim.t[state.tab].review = true
end

--- Load the sections for whatever the review is of, then draw them.
local function load()
  local sections = require("review.sections")
  local function done(found)
    state.sections = found
    draw()
  end
  if state.rev then
    sections.revision(state.root, state.rev.sha, state.rev.parent, done)
  else
    sections.working(state.root, state.base, done)
  end
end

--- Attach the notes for the repository under review, so a row can show its count and a
--- buffer can show its signs.
local function attach_notes(cb)
  require("harness.notes").attach({ state.root }, function()
    cb()
  end)
end

--- Open a review of one repository's working tree.
---@param root string
---@param base string|nil a commit to compare the working tree back to
function M.open(root, base)
  if M.is_open() then
    M.close()
  end
  state.root, state.base, state.rev = root, base, nil
  open_tab()
  attach_notes(load)
end

--- Open a review of one commit.
---@param root string
---@param rev table `{ sha, parent, short }`
function M.open_revision(root, rev)
  if M.is_open() then
    M.close()
  end
  state.root, state.base, state.rev = root, nil, rev
  open_tab()
  attach_notes(load)
end

--- Close the review and everything it opened.
function M.close()
  diff.close()
  inline.close()
  lists.forget()
  pcall(function()
    require("harness.notes").detach()
  end)
  if M.is_open() then
    -- The tab, not the windows: the review owns the tab, and closing it takes the
    -- spine and both sides with it in one step.
    pcall(vim.cmd, state.tab .. "tabclose")
  end
  state.tab, state.root, state.base, state.rev = nil, nil, nil, nil
  state.sections, state.entry = {}, nil
end

--- Open the review of the repository the caller is in, or close the open one. The repo is
--- asked for when the workspace holds several, because a review is of a repository and
--- the file that happens to be open is a poor guess at which one.
function M.toggle()
  if M.is_open() then
    return M.close()
  end
  require("utils.gitrepo").resolve(function(root)
    M.open(root)
  end, { ask = true })
end

--- Reload the sections, keeping the base and the placement.
function M.refresh()
  if not M.is_open() then
    return
  end
  attach_notes(load)
end

--- Swap the spine between a list along the bottom and a tree down the side.
function M.toggle_placement()
  state.placement = state.placement == "bottom" and "tree" or "bottom"
  if M.is_open() then
    attach_notes(load)
  else
    vim.notify("Review: the spine will open as a " .. state.placement, vim.log.levels.INFO)
  end
end

--- Swap the file view between the two sides side by side and the one-window inline
--- reading, redrawing the file already open so the swap costs no place in the review.
function M.toggle_layout()
  state.layout = state.layout == "split" and "inline" or "split"
  if M.is_open() and state.entry ~= nil then
    render(state.entry)
  else
    vim.notify("Review: files will open " .. state.layout, vim.log.levels.INFO)
  end
end

--- Compare the working tree back to a commit, adding the cumulative section.
---@param base string|nil nil drops back to the working tree alone
function M.set_base(base)
  state.base = base ~= "" and base or nil
  if M.is_open() then
    attach_notes(load)
  end
end

--- Open the entry under the cursor in the spine. False when the list is not the
--- review's, so the caller can fall back to opening a file the ordinary way.
---@return boolean handled
function M.activate()
  if not M.is_open() or not lists.is_mine() then
    return false
  end
  local entry = lists.entry_under_cursor()
  if entry == nil then
    return false
  end
  return render(entry)
end

--- Step to the next or previous file in the spine and open it.
---@param delta integer
---@return boolean handled
function M.step(delta)
  if not M.is_open() or not lists.is_mine() then
    return false
  end
  local entry = lists.step(delta)
  if entry == nil then
    -- Off the end of this section rather than nowhere, and the section stays put, so a
    -- reader who wanted the next section reaches for `>`.
    return true
  end
  return render(entry)
end

--- Whether the cursor sits in one of the review's windows.
---@return boolean
function M.here()
  return M.is_open() and vim.api.nvim_get_current_tabpage() == state.tab
end

return M
