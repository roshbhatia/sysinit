local M = {}

local augroup = "harness_changes_list"

local qf_id = nil

---@param status string
---@return string
local function letter(status)
  local index, tree = status:sub(1, 1), status:sub(2, 2)
  if status == "??" then
    return "new"
  end
  if index ~= " " and index ~= "" then
    return index:lower() .. "-staged"
  end
  return tree:lower()
end

-- The repository is a column, not a separate list, so a folder holding several
-- reads exactly like a single one.
---@param cb fun(rows: table[], roots: string[])
local function collect(cb)
  require("utils.gitrepo").workspace_changes(function(groups, roots)
    local notes = require("harness.notes")
    local rows = {}
    for _, group in ipairs(groups) do
      local repo = vim.fn.fnamemodify(group.root, ":t")
      for _, file in ipairs(group.files) do
        local count = #notes.for_file(file.path)
        rows[#rows + 1] = {
          path = file.path,
          repo = repo,
          relative = file.path:sub(#group.root + 2),
          status = letter(file.status),
          notes = count,
        }
      end
    end
    cb(rows, roots)
  end)
end

---@param row table
---@return string
local function label(row)
  local text = string.format("%s  %s/%s", row.status, row.repo, row.relative)
  if row.notes > 0 then
    text = text .. string.format("  󰦢 %d", row.notes)
  end
  return text
end

---@param rows table[]
---@return integer
local function fill(rows)
  local items = {}
  for _, row in ipairs(rows) do
    items[#items + 1] = { filename = row.path, lnum = 1, col = 1, text = label(row) }
  end

  local what = { title = string.format("Changes (%d)", #items), items = items }
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
  collect(function(rows, roots)
    if #rows == 0 then
      local where = vim.fn.fnamemodify(require("utils.gitrepo").workspace(), ":~")
      vim.notify(
        #roots == 0 and ("Changes: no git repository under " .. where) or ("Changes: nothing changed under " .. where),
        vim.log.levels.INFO
      )
      return
    end
    fill(rows)
    vim.cmd("botright copen 10")

    local group = vim.api.nvim_create_augroup(augroup, { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "User" }, {
      group = group,
      pattern = { "*", "HarnessNotesChanged" },
      callback = function()
        if not ours() then
          vim.api.nvim_del_augroup_by_name(augroup)
          return
        end
        collect(function(fresh)
          if ours() then
            fill(fresh)
          end
        end)
      end,
    })
  end)
end

function M.pick()
  collect(function(rows)
    if #rows == 0 then
      vim.notify("Changes: nothing changed under " .. vim.fn.fnamemodify(require("utils.gitrepo").workspace(), ":~"))
      return
    end

    local items = {}
    for index, row in ipairs(rows) do
      items[#items + 1] = {
        idx = index,
        score = 0,
        text = string.format("%s %s %s", row.repo, row.relative, row.status),
        file = row.path,
        row = row,
      }
    end

    Snacks.picker.pick({
      source = "harness_changes",
      items = items,
      format = function(item)
        local parts = {
          { item.row.status .. "  ", "SnacksPickerLabel" },
          { item.row.repo .. "  ", "SnacksPickerDir" },
          { item.row.relative, "SnacksPickerFile" },
        }
        if item.row.notes > 0 then
          parts[#parts + 1] = { string.format("  󰦢 %d", item.row.notes), "SnacksPickerComment" }
        end
        return parts
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
        end
      end,
    })
  end)
end

return M
