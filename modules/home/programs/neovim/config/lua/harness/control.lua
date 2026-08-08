
local M = {}

local NS = vim.api.nvim_create_namespace("harness_control")

local function err(msg)
  return { ok = false, error = msg }
end

---@param path string
---@return integer|nil buf, string|nil errmsg
local function ensure_buf(path)
  local full = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  if vim.fn.filereadable(full) == 0 then
    return nil, "no such file: " .. full
  end
  local buf = vim.fn.bufadd(full)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true
  return buf, nil
end

local START_SCREENS = {
  snacks_dashboard = true,
  dashboard = true,
  alpha = true,
  starter = true,
  ministarter = true,
}

function M.dismiss_start_screen()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if START_SCREENS[vim.bo[buf].filetype] then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

local function prune_empty_windows()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    if #vim.api.nvim_tabpage_list_wins(0) <= 1 then
      return
    end
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local blank = #lines == 0 or (#lines == 1 and lines[1] == "")
      if vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified and blank then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

---@return integer|nil
local function main_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      local bt = vim.bo[buf].buftype
      local ft = vim.bo[buf].filetype
      if bt ~= "terminal" and bt ~= "prompt" and ft ~= "neo-tree" and ft ~= "trouble" then
        return win
      end
    end
  end
  return nil
end

---@param buf integer
---@param split string|nil  "none" | "vsplit" | "split" | "tab"
local function show(buf, split)
  M.dismiss_start_screen()
  if split == "tab" then
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, buf)
    return vim.api.nvim_get_current_win()
  end
  local win = main_win()
  if win then
    vim.api.nvim_set_current_win(win)
  end
  if split == "vsplit" then
    vim.cmd("vsplit")
  elseif split == "split" then
    vim.cmd("split")
  end
  vim.api.nvim_win_set_buf(0, buf)
  local win = vim.api.nvim_get_current_win()
  prune_empty_windows()
  return win
end

---@param win integer
---@param line integer|nil
local function jump(win, line)
  if not line then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local last = vim.api.nvim_buf_line_count(buf)
  local target = math.max(1, math.min(line, last))
  vim.api.nvim_win_set_cursor(win, { target, 0 })
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! zz")
  end)
end

local ops = {}

function ops.open(req)
  local buf, e = ensure_buf(req.path or "")
  if not buf then
    return err(e)
  end
  local win = show(buf, req.split)
  jump(win, req.line)
  return { ok = true, path = vim.api.nvim_buf_get_name(buf), line = req.line }
end

function ops.goto_line(req)
  if not req.line then
    return err("goto_line needs a line")
  end
  jump(vim.api.nvim_get_current_win(), req.line)
  return { ok = true, line = req.line }
end

function ops.highlight(req)
  local buf, e = req.path and ensure_buf(req.path) or vim.api.nvim_get_current_buf()
  if not buf then
    return err(e)
  end
  local from = tonumber(req.from)
  local to = tonumber(req.to) or from
  if not from then
    return err("highlight needs from")
  end
  local last = vim.api.nvim_buf_line_count(buf)
  for line = from, math.min(to, last) do
    vim.api.nvim_buf_set_extmark(buf, NS, line - 1, 0, {
      line_hl_group = "HarnessAgentRange",
      virt_text = (line == from and req.label) and { { "  " .. req.label, "HarnessAgentLabel" } } or nil,
      virt_text_pos = "eol",
    })
  end
  return { ok = true, from = from, to = to }
end

function ops.annotate(req)
  local buf, e = req.path and ensure_buf(req.path) or vim.api.nvim_get_current_buf()
  if not buf then
    return err(e)
  end
  local line = tonumber(req.line)
  if not line or not req.text then
    return err("annotate needs line and text")
  end
  local last = vim.api.nvim_buf_line_count(buf)
  local row = math.max(1, math.min(line, last)) - 1
  local virt = {}
  for _, chunk in ipairs(vim.split(req.text, "\n", { plain = true })) do
    table.insert(virt, { { "  ▏ " .. chunk, "HarnessAgentNote" } })
  end
  vim.api.nvim_buf_set_extmark(buf, NS, row, 0, {
    virt_lines = virt,
    sign_text = "▎",
    sign_hl_group = "HarnessAgentNote",
  })
  return { ok = true, line = line }
end

function ops.split_open(req)
  local buf, e = ensure_buf(req.path or "")
  if not buf then
    return err(e)
  end
  local win = show(buf, req.split or "vsplit")
  jump(win, req.line)
  return { ok = true, path = vim.api.nvim_buf_get_name(buf) }
end

function ops.clear(_req)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    end
  end
  return { ok = true }
end

function ops.diff(req)
  local left, e1 = ensure_buf(req.left or req.path or "")
  if not left then
    return err(e1)
  end
  if req.right then
    local right, e2 = ensure_buf(req.right)
    if not right then
      return err(e2)
    end
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, left)
    vim.cmd("diffthis | vsplit")
    vim.api.nvim_win_set_buf(0, right)
    vim.cmd("diffthis")
    return { ok = true, mode = "pair" }
  end
  show(left, "tab")
  local ok = pcall(vim.cmd, "Gitsigns diffthis")
  return { ok = true, mode = ok and "index" or "buffer" }
end

function ops.context(_req)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local visible = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
    if name ~= "" then
      table.insert(visible, name)
    end
  end
  local listed = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        table.insert(listed, name)
      end
    end
  end
  return {
    ok = true,
    cwd = vim.fn.getcwd(),
    file = vim.api.nvim_buf_get_name(buf),
    line = cursor[1],
    col = cursor[2] + 1,
    filetype = vim.bo[buf].filetype,
    visible = visible,
    buffers = listed,
    agent = require("harness.session").get_active(),
  }
end

function ops.selection(_req)
  local marks = { vim.api.nvim_buf_get_mark(0, "<"), vim.api.nvim_buf_get_mark(0, ">") }
  if marks[1][1] == 0 then
    return { ok = true, empty = true }
  end
  local lines = vim.api.nvim_buf_get_lines(0, marks[1][1] - 1, marks[2][1], false)
  return {
    ok = true,
    file = vim.api.nvim_buf_get_name(0),
    from = marks[1][1],
    to = marks[2][1],
    text = table.concat(lines, "\n"),
  }
end

function ops.diagnostics(req)
  local buf = 0
  if req.path then
    local b, e = ensure_buf(req.path)
    if not b then
      return err(e)
    end
    buf = b
  end
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do
    table.insert(out, {
      line = d.lnum + 1,
      severity = vim.diagnostic.severity[d.severity],
      message = d.message,
      source = d.source,
    })
  end
  return { ok = true, diagnostics = out }
end

function ops.preview(req)
  return require("harness.preview").open(req.path or "", { focus = req.focus ~= false })
end

function ops.notify(req)
  vim.notify(req.text or "", vim.log.levels.INFO)
  return { ok = true }
end

function ops.command(req)
  if not req.command or req.command == "" then
    return err("command needs a command")
  end
  local ok, e = pcall(vim.cmd, req.command)
  if not ok then
    return err(tostring(e))
  end
  return { ok = true }
end

---@return string[]
function M.ops()
  return vim.tbl_keys(ops)
end

function M.clear()
  return ops.clear({})
end

---@param ctl string  path to a file holding one line of JSON: { op = ..., ... }
---@return string     one line of JSON
function M.rpc(ctl)
  local read_ok, lines = pcall(vim.fn.readfile, ctl)
  if not read_ok or not lines[1] then
    return vim.json.encode(err("could not read request file"))
  end
  local decode_ok, req = pcall(vim.json.decode, lines[1])
  if not decode_ok or type(req) ~= "table" then
    return vim.json.encode(err("request was not JSON"))
  end
  local handler = ops[req.op]
  if not handler then
    return vim.json.encode(err("unknown op: " .. tostring(req.op)))
  end
  local ok, res = pcall(handler, req)
  if not ok then
    return vim.json.encode(err(tostring(res)))
  end
  return vim.json.encode(res)
end

function M.setup()
  vim.api.nvim_set_hl(0, "HarnessAgentRange", { link = "Visual", default = true })
  vim.api.nvim_set_hl(0, "HarnessAgentLabel", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "HarnessAgentNote", { link = "DiagnosticVirtualTextInfo", default = true })
  vim.api.nvim_create_user_command("HarnessClearAnnotations", function()
    ops.clear({})
  end, { desc = "Harness: clear agent highlights and annotations" })
end

return M
