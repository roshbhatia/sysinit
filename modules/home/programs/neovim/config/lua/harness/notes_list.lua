local M = {}

local ns = vim.api.nvim_create_namespace("harness_note_markers")
local augroup = "harness_note_list"

local qf_id = nil

---@return table[]
local function notes()
  return require("harness.notes").all()
end

---@param note table
---@return string
local function label(note)
  local text = note.summary or note.text or ""
  return (text:gsub("%s+", " "))
end

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

---@return boolean
local function ours()
  return qf_id ~= nil and vim.fn.getqflist({ id = 0 }).id == qf_id
end

function M.quickfix()
  local count = fill()
  vim.cmd("botright copen 10")

  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "HarnessNotesChanged",
    callback = function()
      if not ours() then
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

---@param root string
---@return table<string, integer>
local function counts_for(root)
  return require("harness.notes").files_in(root)
end

---@param bufnr number
function M.mark_panel(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return
  end
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

  pcall(function()
    components.comp:deep_some(function(comp)
      if comp.name ~= "file" or comp.context == nil then
        return
      end
      local count = counts[comp.context.path]
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
