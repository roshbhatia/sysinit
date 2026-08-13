--- The agent's diff notes, drawn inline in the diff.
local M = {}

--- The command that owns the note record. Named once, so the health check reports on
--- the same binary this reads through and a rename is one edit.
M.tool = "utils"

local ns = vim.api.nvim_create_namespace("harness_agent_notes")
local augroup = "harness_agent_notes"

--- Notes for the open review, by repository root, then by path relative to it.
---@type table<string, table<string, table[]>>
local by_root = {}

--- Which roots the current review covers, longest first, so a file is matched to the
--- innermost repository that contains it.
---@type string[]
local roots = {}

local attached = false

--- The marker for a rule between two notes sharing one box. A control byte, so no
--- note's own text can produce it.
local rule = "\1"

--- One box holding every note on a line.
---@param entries string[]
---@param hl string
---@return table[]
local function box(entries, hl)
  local body = {}
  for index, entry in ipairs(entries) do
    if index > 1 then
      table.insert(body, rule)
    end
    for _, line in ipairs(vim.split(entry, "\n", { plain = true })) do
      table.insert(body, line)
    end
  end

  local width = 20
  for _, line in ipairs(body) do
    if line ~= rule then
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
  end

  -- `[NOTE]`, not `[AGENT]`: `M.add` lets the owner write into the same record.
  local header = #entries > 1 and string.format("[NOTE ×%d]", #entries) or "[NOTE]"
  local lines = {
    { { "╭─" .. header .. string.rep("─", width - vim.fn.strdisplaywidth(header) + 1) .. "╮", hl } },
  }
  for _, line in ipairs(body) do
    if line == rule then
      table.insert(lines, { { "├" .. string.rep("─", width + 2) .. "┤", hl } })
    else
      table.insert(lines, { { "│ " .. line .. string.rep(" ", width - vim.fn.strdisplaywidth(line)) .. " │", hl } })
    end
  end
  table.insert(lines, { { "╰" .. string.rep("─", width + 2) .. "╯", hl } })
  return lines
end

--- The note's own text: the summary, the rationale under it, and who wrote it.
---@param note table
---@return string
local function render(note)
  -- Tested for being a string, not for being truthy: the record writes `null` for a
  -- note with no rationale, `vim.json.decode` turns that into `vim.NIL`, and `vim.NIL`
  -- is truthy. A note added without `--rationale` printed a line reading `vim.NIL`.
  local function said(value)
    return type(value) == "string" and value ~= "" and value or nil
  end
  local text = said(note.summary) or ""
  local author = said(note.author)
  if author then
    text = text .. "\n— " .. author
  end
  local rationale = said(note.rationale)
  if rationale then
    text = text .. "\n" .. rationale
  end
  return text
end

--- Which of the review's roots contains `path`, innermost first.
---@param path string
---@return string|nil root
---@return string|nil relative
local function owner(path)
  for _, root in ipairs(roots) do
    if path:sub(1, #root + 1) == root .. "/" then
      return root, path:sub(#root + 2)
    end
  end
  return nil, nil
end

--- Draw every note that belongs to `bufnr`, replacing what is already drawn.
---@param bufnr number
function M.place(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return
  end
  local root, relative = owner(vim.fs.normalize(name))
  if root == nil then
    return
  end
  local notes = (by_root[root] or {})[relative]
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if notes == nil then
    return
  end
  local last = vim.api.nvim_buf_line_count(bufnr)
  -- Grouped by row before anything is drawn, so a line's notes share one extmark and
  -- therefore one frame and one sign. `rows` keeps the record's order, since the store
  -- is append-only and the oldest note on a line is the first thing written about it.
  local rows, order = {}, {}
  for _, note in ipairs(notes) do
    -- The record's line is 1-based on the new side. A note on a line the file no
    -- longer has still shows, on the last line, because a note the owner cannot see
    -- is worse than a note in the wrong place.
    local row = math.max(0, math.min(tonumber(note.line) or 1, last) - 1)
    if rows[row] == nil then
      rows[row] = {}
      table.insert(order, row)
    end
    table.insert(rows[row], render(note))
  end
  for _, row in ipairs(order) do
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      sign_text = "󰚩",
      sign_hl_group = "DiagnosticInfo",
      virt_lines = box(rows[row], "DiagnosticInfo"),
      virt_lines_above = false,
    })
  end
end

--- Read one repository's notes, then place them in every buffer already open.
---@param root string
---@param done? fun(count: integer)
local function load(root, done)
  -- The tool is checked for rather than assumed.
  if vim.fn.executable(M.tool) ~= 1 then
    by_root[root] = {}
    if done then
      done(0)
    end
    return
  end
  vim.system({ M.tool, "note", "list", "--json" }, { cwd = root, text = true }, function(result)
    local notes = {}
    local count = 0
    if result.code == 0 and result.stdout and result.stdout ~= "" then
      local ok, doc = pcall(vim.json.decode, result.stdout)
      if ok and type(doc) == "table" and type(doc.notes) == "table" then
        for _, note in ipairs(doc.notes) do
          if type(note) == "table" and type(note.file) == "string" then
            notes[note.file] = notes[note.file] or {}
            table.insert(notes[note.file], note)
            count = count + 1
          end
        end
      end
    end
    vim.schedule(function()
      by_root[root] = notes
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        M.place(bufnr)
      end
      -- Announced rather than pushed: a note list, a picker, and the diff panel all want
      -- to know the record moved, and none of them should have to poll for it.
      vim.api.nvim_exec_autocmds("User", { pattern = "HarnessNotesChanged", modeline = false })
      if done then
        done(count)
      end
    end)
  end)
end

--- Show the notes for a set of repository roots for as long as the review is open.
---@param review_roots string[]
---@param on_ready? fun(count: integer)
function M.attach(review_roots, on_ready)
  roots = vim.deepcopy(review_roots)
  -- Longest first: the innermost repository containing a file owns its notes.
  table.sort(roots, function(a, b)
    return #a > #b
  end)
  by_root = {}

  if not attached then
    attached = true
    local group = vim.api.nvim_create_augroup(augroup, { clear = true })
    -- A diff plugin loads the annotated file after the session opens, and a step to
    -- another file loads another. Both are this event, so neither needs a hook of its
    -- own here.
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
      group = group,
      callback = function(args)
        M.place(args.buf)
      end,
    })
  end

  local pending = #roots
  local total = 0
  if pending == 0 then
    if on_ready then
      on_ready(0)
    end
    return
  end
  for _, root in ipairs(roots) do
    load(root, function(count)
      total = total + count
      pending = pending - 1
      if pending == 0 and on_ready then
        on_ready(total)
      end
    end)
  end
end

--- Re-read the notes for the roots already attached.
---@param on_ready? fun(count: integer)
function M.refresh(on_ready)
  if #roots == 0 then
    if on_ready then
      on_ready(0)
    end
    return
  end
  M.attach(roots, on_ready)
end

--- Take the notes back down, in every buffer, and forget them.
function M.detach()
  pcall(vim.api.nvim_del_augroup_by_name, augroup)
  attached = false
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
    end
  end
  by_root = {}
  roots = {}
  vim.api.nvim_exec_autocmds("User", { pattern = "HarnessNotesChanged", modeline = false })
end

--- Write a note on the current line, then redraw it.
function M.add()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.bo[buf].buftype ~= "" then
    vim.notify("Notes: this window holds no file to annotate", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(M.tool) ~= 1 then
    vim.notify("Notes: " .. M.tool .. " is not on PATH", vim.log.levels.ERROR)
    return
  end

  path = vim.fs.normalize(path)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  -- The review's root when one is open, so a note lands in the same record the review
  -- reads; otherwise the repository holding the file, so annotating works with no review.
  local root = owner(path)
  if root == nil then
    root = vim.fs.root(path, ".git")
    if root == nil then
      vim.notify("Notes: " .. path .. " is in no repository", vim.log.levels.WARN)
      return
    end
  end

  vim.ui.input({ prompt = string.format("Note on %s:%d: ", vim.fn.fnamemodify(path, ":t"), line) }, function(summary)
    if summary == nil or summary == "" then
      return
    end
    vim.system({
      M.tool,
      "note",
      "add",
      "--file",
      path,
      "--line",
      tostring(line),
      "--summary",
      summary,
      "--author",
      vim.env.USER or "owner",
    }, { cwd = root, text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify("Notes: " .. (result.stderr or "note add failed"), vim.log.levels.ERROR)
          return
        end
        if #roots == 0 then
          M.attach({ root })
        else
          M.refresh()
        end
      end)
    end)
  end)
end

--- Every note under every attached root, newest root order, each carrying the absolute
--- path it belongs to. For a list or a picker, which needs one flat set rather than the
--- per-buffer view `place` draws.
---@return table[]
function M.all()
  local found = {}
  for _, root in ipairs(roots) do
    for relative, notes in pairs(by_root[root] or {}) do
      for _, note in ipairs(notes) do
        found[#found + 1] = vim.tbl_extend("keep", {
          root = root,
          relative = relative,
          path = root .. "/" .. relative,
        }, note)
      end
    end
  end
  table.sort(found, function(a, b)
    if a.path ~= b.path then
      return a.path < b.path
    end
    return (tonumber(a.line) or 0) < (tonumber(b.line) or 0)
  end)
  return found
end

--- Which files under root carry notes, and how many each carries, for a list that shows
--- a count per row. Keyed the way a note records its file, relative to the root.
---@param root string
---@return table<string, integer>
function M.files_in(root)
  local counts = {}
  for relative, notes in pairs(by_root[root] or {}) do
    counts[relative] = #notes
  end
  return counts
end

--- How many notes are drawn, for the health report.
---@return integer
function M.count()
  local total = 0
  for _, files in pairs(by_root) do
    for _, notes in pairs(files) do
      total = total + #notes
    end
  end
  return total
end

return M
