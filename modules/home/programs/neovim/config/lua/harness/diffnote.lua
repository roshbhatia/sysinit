-- Render agent review notes inside the CodeDiff view.
--
-- An agent leaves notes with the `diffnote` CLI, which writes one JSON file per
-- repository. This module reads that file and draws each note as end-of-line
-- virtual text on its target line in the diff's modified window.
--
-- Virtual TEXT, not virtual lines. codediff replaced native scrollbind with a
-- structural sync whose alignment table counts every `virt_lines` extmark in the
-- buffer across all namespaces (codediff/scrollsync.lua). Notes only anchor on
-- the modified side, because the original side is a git object rather than a file
-- on disk, so filler rows here and none there left the two panes' virtual-row
-- mappings permanently disagreeing and the view scrolled up and down on its own.
-- End-of-line virtual text occupies no row, so the alignment stays symmetric.
-- The full note lives in `M.qflist` and `M.show_at_cursor` instead.
--
-- Watching the file (not talking to the agent) is the same choice spec_watch.lua
-- makes, and for the same reasons: it works for every harness, needs no RPC
-- socket, and needs no cooperation from the CLI beyond writing JSON. The CLI
-- stays a pure writer, so it also works with no nvim running at all.

local M = {}

local NS = vim.api.nvim_create_namespace("sysinit_diffnote")
local DEBOUNCE_MS = 150
-- One row renders as one line of virtual text, so the note count no longer decides
-- how much vertical space is taken. What still needs bounding is WIDTH: a long
-- summary pushes past the window edge and is simply lost, and `rationale` is not
-- rendered inline at all now. Extra notes on a row collapse to a count.
local MAX_SUMMARY_COLS = 90

-- `drawn` is every buffer this module has placed a mark in. M.stop cleared only
-- `nvim_get_current_buf()`, so notes left behind in the reviewer's real file
-- buffers survived closing the view, and nothing but a restart removed them.
local state = { handle = nil, timer = nil, root = nil, notes = nil, drawn = {}, stopped = false }

---@return string|nil
local function repo_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

-- Must match `note_file` in runtime/diffnote.sh. One repository, one file, keyed
-- by the absolute repo root so two checkouts of the same project stay separate.
---@param root string
---@return string
local function note_path(root)
  local state_home = vim.env.XDG_STATE_HOME
  if not state_home or state_home == "" then
    local home = vim.env.HOME
    if not home or home == "" then
      return ""
    end
    state_home = vim.fs.joinpath(home, ".local", "state")
  end
  -- No explicit trailing-slash strip: `vim.fs.joinpath` collapses it, measured. The
  -- shell half has to do it by hand because it builds the path with printf. The
  -- check pins the property from both sides, so this stays correct if joinpath
  -- ever changes.
  local digest = vim.fn.sha256(root):sub(1, 16)
  local name = vim.fs.basename(root)
  return vim.fs.joinpath(state_home, "agents", "diff-notes", name .. "-" .. digest .. ".json")
end

-- Test seam. `checks/diffnote-roundtrip.nix` asserts this against the path
-- `runtime/diffnote.sh` derives, because the two agree only by convention and a
-- drift is silent: the CLI reports success and nothing ever renders.
---@param root string
---@return string
function M._note_path_for(root)
  return note_path(root)
end

---@param root string
---@return table<string, table[]>  repo-relative file path → notes, ascending by line
local function read_notes(root)
  local path = note_path(root)
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" or type(decoded.notes) ~= "table" then
    return {}
  end
  local by_file = {}
  for _, note in ipairs(decoded.notes) do
    -- An integral line of 1 or more, or the note is skipped. A float reached
    -- nvim_buf_set_extmark and was refused inside its pcall, which dropped the
    -- note with no trace.
    -- `summary` is checked as well as `line`. A row renders as ONE extmark, so a
    -- non-string summary made the whole call raise, and the pcall around it then
    -- discarded every valid note sharing that row.
    local usable = type(note) == "table"
      and type(note.file) == "string"
      and type(note.summary) == "string"
      and type(note.line) == "number"
      and note.line >= 1
      and note.line == math.floor(note.line)
    if usable then
      by_file[note.file] = by_file[note.file] or {}
      table.insert(by_file[note.file], note)
    end
  end
  -- Insertion index as the tie-break. `table.sort` is not stable in Lua, and the
  -- per-row cap now decides which notes are visible, so an arbitrary tie-break
  -- reordered the visible notes and hid an arbitrary one.
  for _, notes in pairs(by_file) do
    for index, note in ipairs(notes) do
      note._seq = index
    end
    table.sort(notes, function(left, right)
      if left.line ~= right.line then
        return left.line < right.line
      end
      return left._seq < right._seq
    end)
  end
  return by_file
end

---@param buf integer
---@param root string
---@return string|nil  repo-relative path
local function buf_key(buf, root)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end
  -- CodeDiff shows the original side from a git object, so only a real file on
  -- disk under the repo root can be keyed. That is the modified side, which is
  -- where a note belongs.
  local absolute = vim.fn.fnamemodify(name, ":p")
  local prefix = root:gsub("/*$", "") .. "/"
  if absolute:sub(1, #prefix) ~= prefix then
    return nil
  end
  return absolute:sub(#prefix + 1)
end

-- Attribution goes FIRST, on the summary line, and there is no trailing signature
-- line at all. A trailing "— <author>" was forgeable: `rationale` is split into
-- lines with the same prefix, so a note could render text that read as the owner's
-- own approval of the diff they were reviewing. Nothing here can be forged into
-- the head position, and every body line is indented under it.
--
-- `author` is still self-declared by whatever wrote the note. This makes the claim
-- visible and unambiguous; it does not authenticate it.
---@param note table
---@return string
local function note_author(note)
  return type(note.author) == "string" and note.author ~= "" and note.author or "agent"
end

-- One row of notes renders as ONE line of end-of-line virtual text. The first
-- note is shown; the rest collapse to a count, because there is only one line to
-- spend and a row with five notes would otherwise be an unreadable run-on.
---@param notes table[]
---@return table[]  virtual text chunks
local function render_row(notes)
  local first = notes[1]
  local summary = first.summary:gsub("%s+", " ")
  if vim.fn.strchars(summary) > MAX_SUMMARY_COLS then
    summary = vim.fn.strcharpart(summary, 0, MAX_SUMMARY_COLS - 1) .. "…"
  end
  local chunks = {
    { "  ▎ ", "DiagnosticInfo" },
    { note_author(first) .. ": ", "DiagnosticInfo" },
    { summary, "DiagnosticVirtualTextInfo" },
  }
  if #notes > 1 then
    table.insert(chunks, { (" +%d more"):format(#notes - 1), "Comment" })
  end
  return chunks
end

-- Public so a test can render into a buffer without codediff loaded. `draw_all`
-- only locates the window; this is the part worth asserting on.
---@param buf integer
function M.draw(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  if not state.root or not state.notes then
    return
  end
  local key = buf_key(buf, state.root)
  if not key then
    return
  end
  local notes = state.notes[key]
  if not notes then
    return
  end
  state.drawn[buf] = true
  local last = vim.api.nvim_buf_line_count(buf)
  -- Group by the row each note lands on first, so the per-row cap counts what the
  -- reader actually sees rather than what the store holds.
  local by_row, order = {}, {}
  for _, note in ipairs(notes) do
    -- A note outlives the edit it was written against, so a stale line number
    -- clamps to the end of the buffer rather than dropping the note silently.
    local row = math.max(0, math.min(note.line, last) - 1)
    if not by_row[row] then
      by_row[row] = {}
      table.insert(order, row)
    end
    table.insert(by_row[row], note)
  end

  for _, row in ipairs(order) do
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, 0, {
      virt_text = render_row(by_row[row]),
      virt_text_pos = "eol",
      -- The diff highlights the line underneath; overwriting it would make an
      -- annotated line stop reading as added or changed.
      hl_mode = "combine",
    })
  end
end

---@param tabpage integer|nil
local function draw_all(tabpage)
  -- Every buffer already drawn into, not only the current modified window. A note
  -- REMOVED from the store (`diffnote clear`) otherwise stayed on screen in any
  -- other buffer the reviewer had visited, because nothing redrew it.
  for buf in pairs(state.drawn) do
    if vim.api.nvim_buf_is_valid(buf) then
      M.draw(buf)
    else
      state.drawn[buf] = nil
    end
  end
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return
  end
  local _, mod_win = lifecycle.get_windows(tabpage or vim.api.nvim_get_current_tabpage())
  if mod_win and vim.api.nvim_win_is_valid(mod_win) then
    M.draw(vim.api.nvim_win_get_buf(mod_win))
  end
end

-- Re-read and redraw. Called on the CodeDiff hooks, and by the file watcher when
-- an agent writes a note while the view is already open.
---@param tabpage integer|nil
function M.refresh(tabpage)
  -- A refresh already queued by the watcher's `vim.schedule_wrap` still runs after
  -- stop(), which would repopulate state and draw into a view that is gone.
  if state.stopped then
    return
  end
  -- Recomputed every time, not cached for the process lifetime. One nvim visiting
  -- two repositories kept the first root, so `buf_key` rejected every buffer in
  -- the second one and rendered nothing, silently, until the editor restarted.
  state.root = repo_root()
  if not state.root then
    return
  end
  state.notes = read_notes(state.root)
  draw_all(tabpage)
end

function M.count()
  if not state.notes then
    return 0
  end
  local total = 0
  for _, notes in pairs(state.notes) do
    total = total + #notes
  end
  return total
end

-- Reads the store directly rather than using `state`, so both entry points below
-- work with no CodeDiff view open and without disturbing what is drawn.
---@return string|nil root, table<string, table[]> by_file
local function load()
  local root = repo_root()
  if not root then
    return nil, {}
  end
  return root, read_notes(root)
end

-- Every note in the repository as a quickfix list. This is where the full set
-- lives now that a row renders as one line: `:cnext` walks them, and the
-- rationale that no longer fits inline is on the entry.
function M.qflist()
  local root, by_file = load()
  if not root then
    vim.notify("diffnote: not inside a git repository", vim.log.levels.WARN)
    return
  end
  local items = {}
  for file, notes in pairs(by_file) do
    for _, note in ipairs(notes) do
      local text = note_author(note) .. ": " .. note.summary:gsub("%s+", " ")
      if type(note.rationale) == "string" and note.rationale ~= "" then
        text = text .. "  — " .. note.rationale:gsub("%s+", " ")
      end
      table.insert(items, { filename = vim.fs.joinpath(root, file), lnum = note.line, text = text })
    end
  end
  if #items == 0 then
    vim.notify("diffnote: no notes in this repository", vim.log.levels.INFO)
    return
  end
  table.sort(items, function(left, right)
    if left.filename ~= right.filename then
      return left.filename < right.filename
    end
    return left.lnum < right.lnum
  end)
  vim.fn.setqflist({}, " ", { title = "diffnote", items = items })
  vim.cmd("copen")
end

-- The full text of every note on the cursor's line, including the rationale the
-- inline text drops.
function M.show_at_cursor()
  local root, by_file = load()
  if not root then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local key = buf_key(buf, root)
  local notes = key and by_file[key]
  if not notes then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = {}
  for _, note in ipairs(notes) do
    if note.line == row then
      table.insert(lines, note_author(note) .. ": " .. note.summary)
      if type(note.rationale) == "string" and note.rationale ~= "" then
        for piece in vim.gsplit(note.rationale, "\n", { plain = true }) do
          if piece ~= "" then
            table.insert(lines, "  " .. piece)
          end
        end
      end
    end
  end
  if #lines == 0 then
    vim.notify("diffnote: no note on this line", vim.log.levels.INFO)
    return
  end
  vim.lsp.util.open_floating_preview(lines, "markdown", { border = "rounded", focus = false })
end

---@return boolean started
function M.start()
  state.stopped = false
  if state.handle then
    return true
  end
  state.root = repo_root()
  if not state.root then
    return false
  end
  local path = note_path(state.root)
  if path == "" then
    return false
  end
  local dir = vim.fs.dirname(path)
  vim.fn.mkdir(dir, "p")
  local handle = vim.uv.new_fs_event()
  if not handle then
    return false
  end
  local timer = vim.uv.new_timer()
  if not timer then
    pcall(handle.close, handle)
    return false
  end
  local ok = pcall(function()
    handle:start(dir, {}, function()
      if not state.timer then
        return
      end
      state.timer:stop()
      state.timer:start(
        DEBOUNCE_MS,
        0,
        vim.schedule_wrap(function()
          M.refresh()
        end)
      )
    end)
  end)
  if not ok then
    -- Both handles, not just the fs_event. Closing one and leaking the other left
    -- a live libuv timer with nothing to cancel it.
    pcall(handle.close, handle)
    pcall(timer.close, timer)
    return false
  end
  state.handle, state.timer = handle, timer
  -- Load what is already on disk. Without this, state.notes stayed nil until the
  -- watcher happened to fire, so a note written BEFORE the view opened rendered
  -- nothing at all: reopening a review to reread yesterday's annotations showed
  -- an empty diff, and touching the store was the only recovery. The live path
  -- hid it, because pi writes after `ctrl+b` opens the split and the fs event
  -- then does the first load.
  M.refresh()
  return true
end

function M.stop()
  state.stopped = true
  if state.timer then
    pcall(state.timer.stop, state.timer)
    pcall(state.timer.close, state.timer)
    state.timer = nil
  end
  if state.handle then
    pcall(state.handle.stop, state.handle)
    pcall(state.handle.close, state.handle)
    state.handle = nil
  end
  -- Every buffer drawn into, not whichever one happens to be current. Closing the
  -- view with the cursor in the file explorer left the marks in place.
  for buf in pairs(state.drawn) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_clear_namespace, buf, NS, 0, -1)
    end
  end
  state.drawn = {}
  state.notes, state.root = nil, nil
end

-- A session that quits without CodeDiffClose never called stop(), leaving a live
-- fs_event and timer at exit.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SysinitDiffnote", { clear = true }),
  callback = function()
    M.stop()
  end,
})

return M
