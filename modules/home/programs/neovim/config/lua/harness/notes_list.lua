-- The three ways to see the notes that are not the inline box: a quickfix list, a picker,
-- and a count beside each file in diffview's tree. The inline box says what a note is
-- about; these say where the notes are, which is the question a review of eighteen
-- repositories opens with.
local M = {}

local ns = vim.api.nvim_create_namespace("harness_note_markers")
local augroup = "harness_note_list"

-- The quickfix list this module owns, so a refresh replaces its own list and leaves a
-- file list someone else put there alone.
local qf_id = nil

--- Every note in the project: the repositories under review, or the ones the open files
--- needed.
---@return table[]
local function notes()
  return require("harness.notes").all()
end

--- One line of a note, for a list that has one line per note.
---@param note table
---@return string
local function label(note)
  local text = note.summary or note.text or ""
  return (text:gsub("%s+", " "))
end

--- Fill the quickfix from the notes, keeping the cursor where it was so a refresh under
--- the reader does not move them.
local function fill()
  local items = {}
  for _, note in ipairs(notes()) do
    items[#items + 1] = {
      filename = note.path,
      lnum = tonumber(note.line) or 1,
      col = 1,
      text = label(note),
      type = "I",
    }
  end

  local what = { title = string.format("Notes (%d)", #items), items = items }
  local exists = qf_id ~= nil and vim.fn.getqflist({ id = qf_id, items = 0 }).id == qf_id
  if exists then
    vim.fn.setqflist({}, "r", vim.tbl_extend("force", what, { id = qf_id }))
  else
    vim.fn.setqflist({}, " ", what)
    qf_id = vim.fn.getqflist({ id = 0 }).id
  end
  return #items
end

--- Whether the list on screen is still this module's.
---@return boolean
local function ours()
  return qf_id ~= nil and vim.fn.getqflist({ id = 0 }).id == qf_id
end

--- Show every note in the quickfix, and keep it current. The list follows the record for
--- as long as it is the list on screen: an agent filing a note during the review updates
--- it in place rather than leaving a list that was true when it opened.
function M.quickfix()
  local count = fill()
  vim.cmd("botright copen 10")

  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "HarnessNotesChanged",
    callback = function()
      if not ours() then
        -- The reader replaced the list with something else, so this one stops following.
        vim.api.nvim_del_augroup_by_name(augroup)
        return
      end
      fill()
    end,
  })

  if count == 0 then
    vim.notify("Notes: this project carries none", vim.log.levels.INFO)
  end
end

--- Every note in a picker, previewing the file at the note's line.
function M.pick()
  local found = notes()
  if #found == 0 then
    vim.notify("Notes: this project carries none", vim.log.levels.INFO)
    return
  end

  local items = {}
  for index, note in ipairs(found) do
    local line = tonumber(note.line) or 1
    items[#items + 1] = {
      idx = index,
      score = 0,
      -- Matched on the repository, the file, and the summary together, since a note is
      -- looked for by any of the three.
      text = string.format("%s %s:%d %s", vim.fn.fnamemodify(note.root, ":t"), note.relative, line, label(note)),
      file = note.path,
      pos = { line, 0 },
      note = note,
    }
  end

  Snacks.picker.pick({
    source = "harness_notes",
    items = items,
    format = function(item)
      local note = item.note
      return {
        { vim.fn.fnamemodify(note.root, ":t") .. "  ", "SnacksPickerLabel" },
        { note.relative .. ":" .. (note.line or 1) .. "  ", "SnacksPickerFile" },
        { label(note), "SnacksPickerComment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
        pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(item.note.line) or 1, 0 })
      end
    end,
  })
end

--- How many notes each file under `root` carries, keyed the way diffview names its
--- entries: relative to the repository top level.
---@param root string
---@return table<string, integer>
local function counts_for(root)
  return require("harness.notes").files_in(root)
end

--- Put the note count beside each file in a diffview file panel. Drawn as an extmark
--- after diffview's own render rather than in place of it, because the panel rebuilds its
--- lines on every refresh and anything written into them is lost on the next one.
---@param bufnr number
function M.mark_panel(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return
  end
  -- The view that owns this panel, not the view in front: several repositories are open
  -- at once, each in its own tab, and marking only the front one leaves the rest bare.
  local view
  for _, open in ipairs(lib.views or {}) do
    if open.panel ~= nil and open.panel.bufid == bufnr then
      view = open
      break
    end
  end
  if view == nil then
    return
  end
  local components = view.panel.components
  if components == nil or components.comp == nil then
    return
  end

  local root = view.adapter and view.adapter.ctx and view.adapter.ctx.toplevel
  if root == nil then
    return
  end
  local counts = counts_for(vim.fs.normalize(root))

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_line_count(bufnr)

  -- The render tree, whose leaves are the only place a file and the line it was drawn on
  -- are held together. `deep_some` walks it; returning nothing keeps the walk going.
  pcall(function()
    components.comp:deep_some(function(comp)
      if comp.name ~= "file" or comp.context == nil then
        return
      end
      local count = counts[comp.context.path]
      -- `lstart` is 0-indexed and the panel may have re-rendered shorter since, so the
      -- line is checked rather than trusted.
      if count and comp.lstart >= 0 and comp.lstart < lines then
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, comp.lstart, 0, {
          virt_text = { { string.format("  󰦢 %d", count), "DiagnosticInfo" } },
          virt_text_pos = "eol",
          hl_mode = "combine",
        })
      end
    end)
  end)
end

--- Keep the panel markers and the diff itself current: the markers whenever the panel
--- draws, the diff whenever a file is written or the terminal comes back to the front.
function M.setup()
  local group = vim.api.nvim_create_augroup("harness_note_markers", { clear = true })

  local pending = false
  local function mark_soon()
    if pending then
      return
    end
    pending = true
    vim.defer_fn(function()
      pending = false
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].filetype == "DiffviewFiles" then
        M.mark_panel(buf)
      end
    end, 40)
  end

  vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved", "TextChanged", "WinScrolled" }, {
    group = group,
    pattern = "*",
    callback = function(args)
      if vim.bo[args.buf].filetype == "DiffviewFiles" then
        mark_soon()
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "HarnessNotesChanged",
    callback = mark_soon,
  })

  -- diffview watches the index by itself, which covers a commit or a stage but not an
  -- ordinary write, and a review left open while the work continues should show the work.
  -- Debounced, because a refresh reads the notes of every repository under review and a
  -- write-heavy minute would otherwise start one process per repository per save.
  local queued = false
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
    group = group,
    callback = function()
      if queued then
        return
      end
      queued = true
      vim.defer_fn(function()
        queued = false
        local ok, review = pcall(require, "harness.review")
        if ok and review.is_open() then
          review.refresh({ quiet = true })
        end
      end, 500)
    end,
  })
end

return M
