local M = {}

M.tool = "utils"

local ns = vim.api.nvim_create_namespace("harness_agent_notes")
local augroup = "harness_agent_notes"

---@type table<string, table<string, table[]>>
local by_root = {}

---@type string[]
local roots = {}

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

---@param root string
---@param done? fun(count: integer)
local function load(root, done)
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

local function order_roots()
  table.sort(roots, function(a, b)
    return #a > #b
  end)
end

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

function M.setup()
  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
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

function M.detach()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
    end
  end
  by_root = {}
  roots = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local path = file_of(bufnr)
    if path then
      ensure(path)
    end
  end
  announce()
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

---@return string[]
function M.project_roots()
  if #roots > 0 then
    return vim.deepcopy(roots)
  end
  local path = file_of(vim.api.nvim_get_current_buf())
  local root = path and vim.fs.root(path, ".git")
  return root and { vim.fs.normalize(root) } or {}
end

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

---@param root string
---@param jobs string[][]
---@param said_done string
local function write(root, jobs, said_done)
  if vim.fn.executable(M.tool) ~= 1 then
    vim.notify("Notes: " .. M.tool .. " is not on PATH", vim.log.levels.ERROR)
    return
  end
  local at = 0
  local function next_job()
    at = at + 1
    if at > #jobs then
      if by_root[root] == nil then
        by_root[root] = {}
        table.insert(roots, root)
        order_roots()
      end
      load(root)
      if said_done ~= "" then
        vim.notify(said_done, vim.log.levels.INFO)
      end
      return
    end
    local args = vim.list_extend({ M.tool, "note" }, jobs[at])
    vim.system(args, { cwd = root, text = true }, function(result)
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
      {
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
      },
    }, "")
  end)
end

function M.remove_line()
  local root = here()
  if root == nil then
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
  write(root, jobs, string.format("Notes: removed %d on line %d", #jobs, line))
end

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
    { { "clear", "--file", path } },
    string.format("Notes: removed %d in %s", count, vim.fn.fnamemodify(path, ":t"))
  )
end

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
    write(root, { { "clear", "--yes" } }, "")
  end
  vim.notify(string.format("Notes: removed %d across the project", count), vim.log.levels.INFO)
end

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

---@param root string
---@return table<string, integer>
function M.files_in(root)
  local counts = {}
  for relative, notes in pairs(by_root[root] or {}) do
    counts[relative] = #notes
  end
  return counts
end

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
