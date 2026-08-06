-- Render agent review notes inside the CodeDiff view.
--
-- An agent leaves notes with the `diffnote` CLI, which writes one JSON file per
-- repository. This module reads that file and draws each note as virtual lines
-- above its target line in the diff's modified window.
--
-- Watching the file (not talking to the agent) is the same choice spec_watch.lua
-- makes, and for the same reasons: it works for every harness, needs no RPC
-- socket, and needs no cooperation from the CLI beyond writing JSON. The CLI
-- stays a pure writer, so it also works with no nvim running at all.

local M = {}

local NS = vim.api.nvim_create_namespace("sysinit_diffnote")
local DEBOUNCE_MS = 150
-- Notes accumulate: nothing prunes the store, and every review of the same hunk
-- adds another. Past this much on one row the block stops being readable, so the
-- rest collapse to a count. `diffnote clear` is how they actually go away.
--
-- Bounded on RENDERED LINES as well as note count. A count alone did not hold the
-- stated property: `rationale` keeps its newlines by contract and nothing bounds its
-- length, so one note with a 400-line rationale pushed the code off screen.
local MAX_NOTES_PER_ROW = 3
local MAX_LINES_PER_ROW = 12

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
---@return table[][]  virtual line chunks
local function render_note(note)
  local author = type(note.author) == "string" and note.author ~= "" and note.author or "agent"
  local lines = {
    {
      { "▎ ", "DiagnosticInfo" },
      { author .. ": ", "DiagnosticInfo" },
      { note.summary, "DiagnosticVirtualTextInfo" },
    },
  }
  if type(note.rationale) == "string" and note.rationale ~= "" then
    for piece in vim.gsplit(note.rationale, "\n", { plain = true }) do
      if piece ~= "" then
        table.insert(lines, { { "▎   ", "DiagnosticInfo" }, { piece, "Comment" } })
      end
    end
  end
  return lines
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
    local row_notes = by_row[row]
    local lines, shown = {}, 0
    for index, note in ipairs(row_notes) do
      local rendered = render_note(note)
      local over_notes = index > MAX_NOTES_PER_ROW
      local over_lines = #lines > 0 and (#lines + #rendered) > MAX_LINES_PER_ROW
      if over_notes or over_lines then
        local hidden = #row_notes - shown
        table.insert(lines, {
          { "▎ ", "DiagnosticInfo" },
          { ("+%d more note%s"):format(hidden, hidden == 1 and "" or "s"), "Comment" },
        })
        break
      end
      vim.list_extend(lines, rendered)
      shown = shown + 1
    end
    -- A single note longer than the line budget is still truncated, so one long
    -- rationale cannot push the code off screen either.
    if #lines > MAX_LINES_PER_ROW + 1 then
      local dropped = #lines - MAX_LINES_PER_ROW
      lines = vim.list_slice(lines, 1, MAX_LINES_PER_ROW)
      table.insert(lines, {
        { "▎ ", "DiagnosticInfo" },
        { ("+%d more line%s"):format(dropped, dropped == 1 and "" or "s"), "Comment" },
      })
    end
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, 0, {
      virt_lines = lines,
      virt_lines_above = true,
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
