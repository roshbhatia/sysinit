
local M = {}

local NS = vim.api.nvim_create_namespace("sysinit_diffnote")
local DEBOUNCE_MS = 150
local MAX_SUMMARY_COLS = 90

local state = { handle = nil, timer = nil, root = nil, notes = nil, drawn = {}, stopped = false }

---@return string|nil
local function repo_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

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
  local digest = vim.fn.sha256(root):sub(1, 16)
  local name = vim.fs.basename(root)
  return vim.fs.joinpath(state_home, "agents", "diff-notes", name .. "-" .. digest .. ".json")
end

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
  local absolute = vim.fn.fnamemodify(name, ":p")
  local prefix = root:gsub("/*$", "") .. "/"
  if absolute:sub(1, #prefix) ~= prefix then
    return nil
  end
  return absolute:sub(#prefix + 1)
end

---@param note table
---@return string
local function note_author(note)
  return type(note.author) == "string" and note.author ~= "" and note.author or "agent"
end

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
  local by_row, order = {}, {}
  for _, note in ipairs(notes) do
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
      hl_mode = "combine",
    })
  end
end

---@param tabpage integer|nil
local function draw_all(tabpage)
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

---@param tabpage integer|nil
function M.refresh(tabpage)
  if state.stopped then
    return
  end
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

---@return string|nil root, table<string, table[]> by_file
local function load()
  local root = repo_root()
  if not root then
    return nil, {}
  end
  return root, read_notes(root)
end

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
    pcall(handle.close, handle)
    pcall(timer.close, timer)
    return false
  end
  state.handle, state.timer = handle, timer
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
  for buf in pairs(state.drawn) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_clear_namespace, buf, NS, 0, -1)
    end
  end
  state.drawn = {}
  state.notes, state.root = nil, nil
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SysinitDiffnote", { clear = true }),
  callback = function()
    M.stop()
  end,
})

return M
