--- The agent's diff notes, drawn inline in the diff.
---
--- `sysinit-agent note add` has always written notes. Nothing rendered them: the
--- export it publishes is shaped for `hunk`'s `--agent-context`, and that viewer was
--- removed, so a note reached a JSON file and stopped. This module is the missing
--- half, and it is a layer rather than a feature of one diff plugin:
---
--- - It reads through `sysinit-agent note list --json` rather than the keyed path, so
---   the note record's location and schema stay owned by the tool that writes them.
--- - It owns its own extmark namespace, so it composes with review.nvim's comment
---   layer instead of sharing a store with it. An agent note is not an owner comment
---   and must not be sent back to the agent as one.
--- - It knows nothing about codediff. It annotates a buffer whose file has notes,
---   which is why the plain `<leader>dd` diff shows them as well as `<leader>dr`.
local M = {}

local ns = vim.api.nvim_create_namespace("harness_agent_notes")
local augroup = "harness_agent_notes"

--- Notes for the open review, by repository root, then by path relative to it.
---@type table<string, table<string, table[]>>
local by_root = {}

--- Which roots the current review covers, longest first, so a file is matched to the
--- innermost repository that contains it. The same rule the review itself uses: a
--- workspace that is itself a repository contains every nested one.
---@type string[]
local roots = {}

local attached = false

---@param text string
---@param hl string
---@return table[]
local function box(text, hl)
  local lines = {}
  local body = vim.split(text, "\n", { plain = true })
  local width = 20
  for _, line in ipairs(body) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  local header = "[AGENT]"
  table.insert(
    lines,
    { { "╭─" .. header .. string.rep("─", width - vim.fn.strdisplaywidth(header) + 1) .. "╮", hl } }
  )
  for _, line in ipairs(body) do
    table.insert(lines, { { "│ " .. line .. string.rep(" ", width - vim.fn.strdisplaywidth(line)) .. " │", hl } })
  end
  table.insert(lines, { { "╰" .. string.rep("─", width + 2) .. "╯", hl } })
  return lines
end

--- The note's own text: the summary, the rationale under it, and who wrote it.
---
--- The author is on the header line rather than in the box body because it is the
--- one field that answers "is this mine or the agent's" at a glance.
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
  for _, note in ipairs(notes) do
    -- The record's line is 1-based on the new side. A note on a line the file no
    -- longer has still shows, on the last line, because a note the owner cannot see
    -- is worse than a note in the wrong place.
    local row = math.max(0, math.min(tonumber(note.line) or 1, last) - 1)
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      sign_text = "󰚩",
      sign_hl_group = "DiagnosticInfo",
      virt_lines = box(render(note), "DiagnosticInfo"),
      virt_lines_above = false,
    })
  end
end

--- Read one repository's notes, then place them in every buffer already open.
---
--- Through the CLI rather than the file, so this module holds no copy of the keyed
--- path or the record schema. One process per repository, at open, not per buffer.
---@param root string
---@param done? fun(count: integer)
local function load(root, done)
  vim.system({ "sysinit-agent", "note", "list", "--json" }, { cwd = root, text = true }, function(result)
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
      if done then
        done(count)
      end
    end)
  end)
end

--- Show the notes for a set of repository roots for as long as the review is open.
---
--- `on_ready` is called once with the total, so the caller can say how many notes the
--- review carries in the same message that says what it opened.
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
---
--- The note record changes outside the editor, from an agent writing while the review
--- is open, and `sysinit-agent note`'s own help says a running viewer picks up nothing
--- on its own. This is how it does.
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
