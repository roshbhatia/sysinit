--- The notes on a working-tree diff, drawn inline: an agent's reasoning about a change,
--- and the owner's questions back to it.
local M = {}

--- The command that owns the note record. Named once, so the health check reports on
--- the same binary this reads through and a rename is one edit.
M.tool = "utils"

local ns = vim.api.nvim_create_namespace("harness_agent_notes")
local augroup = "harness_agent_notes"

--- Notes for the loaded projects, by repository root, then by path relative to it.
---@type table<string, table<string, table[]>>
local by_root = {}

--- Which roots are loaded, longest first, so a file is matched to the innermost
--- repository that contains it.
---@type string[]
local roots = {}

--- Whether the boxes are drawn. The record is read either way, so the statusline can
--- still say a file carries notes while they are hidden.
local shown = true

--- The marker for a rule between two notes sharing one box. A control byte, so no
--- note's own text can produce it.
local rule = "\1"

--- The value of a field the record may have written as JSON null, which `vim.json.decode`
--- turns into `vim.NIL`, which is truthy. A note added with no rationale printed a line
--- reading `vim.NIL` before this was tested for being a string.
---@param value any
---@return string|nil
local function said(value)
  return type(value) == "string" and value ~= "" and value or nil
end

--- The glyph each harness is drawn with, keyed by both the adapter's name and the name a
--- note's author carries. Taken from the adapters rather than copied, so a harness that
--- changes its icon changes it here too.
---@type table<string, string>|nil
local marks = nil

---@param author string
---@return string|nil
local function glyph_for(author)
  if marks == nil then
    marks = {}
    local ok, registry = pcall(require, "harness.registry")
    if ok then
      for _, adapter in ipairs(registry.get_all()) do
        local glyph, word = tostring(adapter.label or ""):match("^(%S+)%s+(%S+)")
        if glyph then
          marks[adapter.name] = glyph
          marks[word:lower()] = glyph
        end
      end
    end
  end
  return marks[author:lower()]
end

--- Who wrote a note. Recorded since the record grew an origin; inferred from the author
--- for a note written before it, where an address is the only thing a person's name has
--- that an agent's does not.
---@param note table
---@return "agent"|"user"
local function origin_of(note)
  local origin = said(note.origin)
  if origin == "user" or origin == "agent" then
    return origin
  end
  return (said(note.author) or ""):find("@", 1, true) and "user" or "agent"
end

--- What the box says about a note's author: the person's address, or the agent's own
--- icon. The name of an agent this config does not know is spelled out beside a generic
--- one, because an unnamed note is worse than an ugly one.
---@param note table
---@return string
local function title(note)
  local author = said(note.author)
  if origin_of(note) == "user" then
    return author or "owner"
  end
  if author == nil then
    return "󰚩"
  end
  return glyph_for(author) or ("󰚩 " .. author)
end

--- One box holding every note on a line, each under its own author.
---@param entries { title: string, body: string }[]
---@param hl string
---@return table[]
local function box(entries, hl)
  local body = {}
  for index, entry in ipairs(entries) do
    if index > 1 then
      table.insert(body, rule)
    end
    for _, line in ipairs(vim.split(entry.body, "\n", { plain = true })) do
      table.insert(body, line)
    end
  end

  local headers = {}
  for index, entry in ipairs(entries) do
    headers[index] = "[" .. entry.title .. "]"
  end

  local width = 20
  for _, line in ipairs(body) do
    if line ~= rule then
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
  end
  for _, header in ipairs(headers) do
    width = math.max(width, vim.fn.strdisplaywidth(header))
  end

  --- A border carrying the author of the note that starts under it.
  local function edge(left, header, right)
    return left .. "─" .. header .. string.rep("─", width - vim.fn.strdisplaywidth(header) + 1) .. right
  end

  local lines = { { { edge("╭", headers[1], "╮"), hl } } }
  local at = 1
  for _, line in ipairs(body) do
    if line == rule then
      at = at + 1
      table.insert(lines, { { edge("├", headers[at], "┤"), hl } })
    else
      table.insert(lines, { { "│ " .. line .. string.rep(" ", width - vim.fn.strdisplaywidth(line)) .. " │", hl } })
    end
  end
  table.insert(lines, { { "╰" .. string.rep("─", width + 2) .. "╯", hl } })
  return lines
end

--- The note's own text: the summary and the rationale under it. Not the author, which
--- the box draws in its frame.
---@param note table
---@return string
local function render(note)
  local text = said(note.summary) or ""
  local rationale = said(note.rationale)
  if rationale then
    text = text .. "\n" .. rationale
  end
  return text
end

--- Which loaded root contains `path`, innermost first.
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

--- The file a buffer holds, or nil for a buffer that holds none.
---@param bufnr number
---@return string|nil
local function file_of(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return vim.fs.normalize(name)
end

--- The notes on the file a buffer holds.
---@param bufnr number
---@return table[]
local function notes_for(bufnr)
  local path = file_of(bufnr)
  if path == nil then
    return {}
  end
  local root, relative = owner(path)
  if root == nil then
    return {}
  end
  return (by_root[root] or {})[relative] or {}
end

--- Draw every note that belongs to `bufnr`, replacing what is already drawn.
---@param bufnr number
function M.place(bufnr)
  local path = file_of(bufnr)
  if path == nil then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not shown then
    return
  end
  local notes = notes_for(bufnr)
  if #notes == 0 then
    return
  end
  local last = vim.api.nvim_buf_line_count(bufnr)
  -- Grouped by row before anything is drawn, so a line's notes share one extmark and
  -- therefore one frame. `rows` keeps the record's order, since the store is append-only
  -- and the oldest note on a line is the first thing written about it.
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
    table.insert(rows[row], { title = title(note), body = render(note) })
  end
  for _, row in ipairs(order) do
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      virt_lines = box(rows[row], "DiagnosticInfo"),
      virt_lines_above = false,
    })
  end
end

--- Say the record moved. A note list, a picker, the diff panel, and the statusline all
--- want to know, and none of them should have to poll for it.
local function announce()
  vim.api.nvim_exec_autocmds("User", { pattern = "HarnessNotesChanged", modeline = false })
  pcall(vim.cmd.redrawstatus, { bang = true })
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
      announce()
      if done then
        done(count)
      end
    end)
  end)
end

--- Keep the roots innermost-first, which is the order `owner` reads them in.
local function order_roots()
  table.sort(roots, function(a, b)
    return #a > #b
  end)
end

--- Load the repository holding `path` if nothing loaded covers it. This is what makes a
--- file carry its notes with no review open: the boxes are the record, not a mode.
---@param path string
local function ensure(path)
  if owner(path) ~= nil then
    return
  end
  local root = vim.fs.root(path, ".git")
  if root == nil then
    return
  end
  root = vim.fs.normalize(root)
  if by_root[root] ~= nil then
    return
  end
  by_root[root] = {}
  table.insert(roots, root)
  order_roots()
  load(root)
end

--- Draw the notes in every buffer as it is shown, loading a repository the first time a
--- file under it is opened.
function M.setup()
  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
  -- A diff plugin loads the annotated file after the session opens, and a step to
  -- another file loads another. Both are this event, so neither needs a hook of its
  -- own here.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
    group = group,
    callback = function(args)
      local path = file_of(args.buf)
      if path == nil then
        return
      end
      ensure(path)
      M.place(args.buf)
    end,
  })
end

--- Load a set of repository roots at once, for a review that opens several.
---@param review_roots string[]
---@param on_ready? fun(count: integer)
function M.attach(review_roots, on_ready)
  roots = vim.deepcopy(review_roots)
  for index, root in ipairs(roots) do
    roots[index] = vim.fs.normalize(root)
  end
  order_roots()
  by_root = {}

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

--- Re-read the notes for every loaded root.
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

--- End a review: drop the repositories it opened. This is not the off switch, which is
--- `toggle`; the notes on a file the owner still has open stay drawn.
function M.detach()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
    end
  end
  by_root = {}
  roots = {}
  -- The repositories the open files need are loaded again: a file the owner is still
  -- looking at keeps its notes, and only the rest of the review's repositories go.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local path = file_of(bufnr)
    if path then
      ensure(path)
    end
  end
  announce()
end

--- Show or hide every box, leaving the record loaded either way.
function M.toggle()
  shown = not shown
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.place(bufnr)
  end
  announce()
end

--- What the statusline says about the file in `bufnr`: how many notes it carries, and
--- whether they are on screen.
---@param bufnr? number
---@return { count: integer, shown: boolean }
function M.status(bufnr)
  return { count = #notes_for(bufnr or vim.api.nvim_get_current_buf()), shown = shown }
end

--- The address git commits under, which is who a note the owner writes is from. Read
--- once per root: it is a file read behind a process, and this runs on every note.
---@type table<string, string>
local emails = {}

---@param root string
---@return string
local function email(root)
  if emails[root] == nil then
    local result = vim.system({ "git", "-C", root, "config", "user.email" }, { text = true }):wait()
    local found = result.code == 0 and vim.trim(result.stdout or "") or ""
    emails[root] = found ~= "" and found or (vim.env.USER or "owner")
  end
  return emails[root]
end

--- The repositories a project-wide command covers: every loaded root, or the one holding
--- the current file when nothing is loaded yet.
---@return string[]
function M.project_roots()
  if #roots > 0 then
    return vim.deepcopy(roots)
  end
  local path = file_of(vim.api.nvim_get_current_buf())
  local root = path and vim.fs.root(path, ".git")
  return root and { vim.fs.normalize(root) } or {}
end

--- The file the cursor is in, as a root and a path, or nil with the reason said out loud.
---@return string|nil root
---@return string|nil path
local function here()
  local buf = vim.api.nvim_get_current_buf()
  local path = file_of(buf)
  if path == nil then
    vim.notify("Notes: this window holds no file to annotate", vim.log.levels.WARN)
    return nil, nil
  end
  local root = owner(path)
  if root == nil then
    root = vim.fs.root(path, ".git")
    if root == nil then
      vim.notify("Notes: " .. path .. " is in no repository", vim.log.levels.WARN)
      return nil, nil
    end
    root = vim.fs.normalize(root)
  end
  return root, path
end

--- Run one `utils note` write and reload what it changed.
---@param root string
---@param args string[]
---@param said_done string
local function write(root, args, said_done)
  if vim.fn.executable(M.tool) ~= 1 then
    vim.notify("Notes: " .. M.tool .. " is not on PATH", vim.log.levels.ERROR)
    return
  end
  vim.system(vim.list_extend({ M.tool, "note" }, args), { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("Notes: " .. (result.stderr or "the write failed"), vim.log.levels.ERROR)
        return
      end
      if by_root[root] == nil then
        by_root[root] = {}
        table.insert(roots, root)
        order_roots()
      end
      load(root)
      if said_done ~= "" then
        vim.notify(said_done, vim.log.levels.INFO)
      end
    end)
  end)
end

--- Write a note on the current line, then redraw it.
function M.add()
  local root, path = here()
  if root == nil then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]

  vim.ui.input({ prompt = string.format("Note on %s:%d: ", vim.fn.fnamemodify(path, ":t"), line) }, function(summary)
    if summary == nil or summary == "" then
      return
    end
    write(root, {
      "add",
      "--file",
      path,
      "--line",
      tostring(line),
      "--summary",
      summary,
      "--author",
      email(root),
      "--origin",
      "user",
    }, "")
  end)
end

--- Take the notes off the current line.
function M.remove_line()
  local root, path = here()
  if root == nil then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local on_line = 0
  for _, note in ipairs(notes_for(vim.api.nvim_get_current_buf())) do
    if (tonumber(note.line) or 0) == line then
      on_line = on_line + 1
    end
  end
  if on_line == 0 then
    vim.notify("Notes: nothing noted on line " .. line, vim.log.levels.INFO)
    return
  end
  write(
    root,
    { "clear", "--file", path, "--line", tostring(line) },
    string.format("Notes: removed %d on line %d", on_line, line)
  )
end

--- Take every note off the current file.
function M.remove_file()
  local root, path = here()
  if root == nil then
    return
  end
  local count = #notes_for(vim.api.nvim_get_current_buf())
  if count == 0 then
    vim.notify("Notes: nothing noted in " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
    return
  end
  local ask = string.format("Remove %d note(s) in %s?", count, vim.fn.fnamemodify(path, ":t"))
  if vim.fn.confirm(ask, "&Yes\n&No", 2) ~= 1 then
    return
  end
  write(
    root,
    { "clear", "--file", path },
    string.format("Notes: removed %d in %s", count, vim.fn.fnamemodify(path, ":t"))
  )
end

--- Take every note off every repository in the project.
function M.remove_project()
  local covered = M.project_roots()
  if #covered == 0 then
    vim.notify("Notes: this project has no repository loaded", vim.log.levels.WARN)
    return
  end
  local count = M.count()
  if count == 0 then
    vim.notify("Notes: this project carries none", vim.log.levels.INFO)
    return
  end
  local ask = string.format("Remove all %d note(s) across %d repositor(y/ies)?", count, #covered)
  if vim.fn.confirm(ask, "&Yes\n&No", 2) ~= 1 then
    return
  end
  for _, root in ipairs(covered) do
    write(root, { "clear", "--yes" }, "")
  end
  vim.notify(string.format("Notes: removed %d across the project", count), vim.log.levels.INFO)
end

--- Every note under every loaded root, each carrying the absolute path it belongs to. For
--- a list or a picker, which needs one flat set rather than the per-buffer view `place`
--- draws.
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

--- How many notes are loaded, for the health report and the project-wide prompt.
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
