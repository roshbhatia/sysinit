local M = {}

M.tool = "utils"

local ns = vim.api.nvim_create_namespace("harness_agent_notes")
local augroup = "harness_agent_notes"

-- A note is addressed by the absolute path of the file it annotates, which is
-- the same key the record uses. There is no repository or workspace to resolve,
-- so one repository and a folder holding several read through one code path.
---@type table<string, table[]>
local by_file = {}

local shown = true

local rule = "\1"

---@param value any
---@return string|nil
local function said(value)
  return type(value) == "string" and value ~= "" and value or nil
end

---@type table<string, string>|nil
local marks = nil

---@param author string
---@return string|nil
local function glyph_for(author)
  if marks == nil then
    marks = {}
    -- Every agent, not only the ones on PATH: a note outlives the agent that
    -- wrote it, and an uninstalled agent's notes still need their mark.
    for _, agent in ipairs(require("harness.launch").all()) do
      local glyph = tostring(agent.glyph or "")
      if glyph ~= "" then
        marks[agent.name] = glyph
        local word = tostring(agent.label or ""):match("^(%S+)")
        if word then
          marks[word:lower()] = glyph
        end
      end
    end
  end
  return marks[author:lower()]
end

---@param note table
---@return "agent"|"user"
local function origin_of(note)
  local origin = said(note.origin)
  if origin == "user" or origin == "agent" then
    return origin
  end
  return (said(note.author) or ""):find("@", 1, true) and "user" or "agent"
end

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

---@param path string
---@return table[]
function M.for_file(path)
  return by_file[vim.fs.normalize(path)] or {}
end

---@param bufnr number
---@return table[]
local function notes_for(bufnr)
  local path = file_of(bufnr)
  return path and M.for_file(path) or {}
end

-- The extmark carries the note after it is placed, so a note stays on its line
-- while the buffer is edited. The record is re-read only on refresh, and the
-- writer re-anchors on the line's own text, so the two never fight.
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
  local notes = M.for_file(path)
  if #notes == 0 then
    return
  end
  local last = vim.api.nvim_buf_line_count(bufnr)
  local rows, order, waiting = {}, {}, {}
  for _, note in ipairs(notes) do
    local row = math.max(0, math.min(tonumber(note.line) or 1, last) - 1)
    if rows[row] == nil then
      rows[row] = {}
      table.insert(order, row)
    end
    table.insert(rows[row], { title = title(note), body = render(note) })
    waiting[row] = waiting[row] or said(note.state) == "open"
  end
  for _, row in ipairs(order) do
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
      virt_lines = box(rows[row], waiting[row] and "DiagnosticWarn" or "DiagnosticInfo"),
      virt_lines_above = false,
    })
  end
end

local function announce()
  vim.api.nvim_exec_autocmds("User", { pattern = "HarnessNotesChanged", modeline = false })
  pcall(vim.cmd.redrawstatus, { bang = true })
end

---@param done? fun(count: integer)
function M.refresh(done)
  if vim.fn.executable(M.tool) ~= 1 then
    by_file = {}
    if done then
      done(0)
    end
    return
  end
  vim.system({ M.tool, "note", "list", "--json" }, { text = true }, function(result)
    local found, count = {}, 0
    if result.code == 0 and result.stdout and result.stdout ~= "" then
      local ok, doc = pcall(vim.json.decode, result.stdout)
      if ok and type(doc) == "table" and type(doc.notes) == "table" then
        for _, note in ipairs(doc.notes) do
          if type(note) == "table" and type(note.file) == "string" then
            local path = vim.fs.normalize(note.file)
            found[path] = found[path] or {}
            table.insert(found[path], note)
            count = count + 1
          end
        end
      end
    end
    vim.schedule(function()
      by_file = found
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

function M.setup()
  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
    group = group,
    callback = function(args)
      M.place(args.buf)
    end,
  })
  M.refresh()
end

function M.toggle()
  shown = not shown
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.place(bufnr)
  end
  announce()
end

---@param bufnr? number
---@return { count: integer, shown: boolean }
function M.status(bufnr)
  return { count = #notes_for(bufnr or vim.api.nvim_get_current_buf()), shown = shown }
end

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

---@param path string
---@return string|nil
local function repo_of(path)
  local root = vim.fs.root(path, ".git")
  return root and vim.fs.normalize(root) or nil
end

---@return string|nil
local function here()
  local path = file_of(vim.api.nvim_get_current_buf())
  if path == nil then
    vim.notify("Notes: this window holds no file to annotate", vim.log.levels.WARN)
  end
  return path
end

---@param jobs string[][]
---@param said_done string
local function write(jobs, said_done)
  if vim.fn.executable(M.tool) ~= 1 then
    vim.notify("Notes: " .. M.tool .. " is not on PATH", vim.log.levels.ERROR)
    return
  end
  local at = 0
  local function next_job()
    at = at + 1
    if at > #jobs then
      M.refresh()
      if said_done ~= "" then
        vim.notify(said_done, vim.log.levels.INFO)
      end
      return
    end
    local args = vim.list_extend({ M.tool, "note" }, jobs[at])
    vim.system(args, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify("Notes: " .. (result.stderr or "the write failed"), vim.log.levels.ERROR)
          return
        end
        next_job()
      end)
    end)
  end
  next_job()
end

function M.add()
  local path = here()
  if path == nil then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local author = email(repo_of(path) or vim.fs.dirname(path))

  vim.ui.input({ prompt = string.format("Note on %s:%d: ", vim.fn.fnamemodify(path, ":t"), line) }, function(summary)
    if summary == nil or summary == "" then
      return
    end
    write({
      { "add", "--file", path, "--line", tostring(line), "--summary", summary, "--author", author, "--origin", "user" },
    }, "")
  end)
end

function M.remove_line()
  if here() == nil then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local jobs = {}
  for _, note in ipairs(notes_for(vim.api.nvim_get_current_buf())) do
    if (tonumber(note.line) or 0) == line and said(note.id) then
      jobs[#jobs + 1] = { "clear", "--id", note.id }
    end
  end
  if #jobs == 0 then
    vim.notify("Notes: nothing noted on line " .. line, vim.log.levels.INFO)
    return
  end
  write(jobs, string.format("Notes: removed %d on line %d", #jobs, line))
end

function M.remove_file()
  local path = here()
  if path == nil then
    return
  end
  local short = vim.fn.fnamemodify(path, ":t")
  local count = #M.for_file(path)
  if count == 0 then
    vim.notify("Notes: nothing noted in " .. short, vim.log.levels.INFO)
    return
  end
  if vim.fn.confirm(string.format("Remove %d note(s) in %s?", count, short), "&Yes\n&No", 2) ~= 1 then
    return
  end
  write({ { "clear", "--file", path } }, string.format("Notes: removed %d in %s", count, short))
end

function M.remove_all()
  local count = M.count()
  if count == 0 then
    vim.notify("Notes: there are none", vim.log.levels.INFO)
    return
  end
  if vim.fn.confirm(string.format("Remove all %d note(s), in every repository?", count), "&Yes\n&No", 2) ~= 1 then
    return
  end
  write({ { "clear", "--yes" } }, string.format("Notes: removed all %d", count))
end

-- Every note, newest repository grouping computed from the file's own git root
-- so a reader can label a row without the note carrying a repository key.
---@return table[]
function M.all()
  local found = {}
  for path, notes in pairs(by_file) do
    local root = repo_of(path)
    for _, note in ipairs(notes) do
      found[#found + 1] = vim.tbl_extend("keep", {
        path = path,
        root = root or vim.fs.dirname(path),
        relative = root and path:sub(#root + 2) or path,
      }, note)
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

---@param root string
---@return table<string, integer>
function M.files_in(root)
  root = vim.fs.normalize(root)
  local counts = {}
  for path, notes in pairs(by_file) do
    if path:sub(1, #root + 1) == root .. "/" then
      counts[path:sub(#root + 2)] = #notes
    end
  end
  return counts
end

---@return integer
function M.count()
  local total = 0
  for _, notes in pairs(by_file) do
    total = total + #notes
  end
  return total
end

return M
