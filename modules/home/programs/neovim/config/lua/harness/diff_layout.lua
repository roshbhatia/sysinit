local M = {}

-- diffview puts the two versions of a file side by side, so a left panel only
-- earns its columns once both halves still clear roughly 64 each.
local SIDE_MIN_COLUMNS = 160

---@param n number
---@param lo integer
---@param hi integer
---@return integer
local function clamp(n, lo, hi)
  return math.floor(math.max(lo, math.min(hi, n)))
end

---@return boolean
local function side_by_side()
  return vim.o.columns >= SIDE_MIN_COLUMNS
end

---@return table
function M.file_panel()
  if side_by_side() then
    return { type = "split", position = "left", width = clamp(vim.o.columns * 0.2, 30, 44) }
  end
  return { type = "split", position = "bottom", height = clamp(vim.o.lines * 0.25, 7, 14) }
end

---@return table
function M.file_history_panel()
  -- Log rows are wide whatever the pane looks like, so this one only scales.
  return { type = "split", position = "bottom", height = clamp(vim.o.lines * 0.3, 10, 18) }
end

---@param panel table
---@return "row"|"column"|nil
local function wanted_form(panel)
  local ok, config = pcall(panel.get_config, panel)
  if not ok then
    return nil
  end
  return vim.tbl_contains({ "top", "bottom" }, config.position) and "row" or "column"
end

---Every get_config() call rewrites panel.state.form, so read the window instead:
---only a top or bottom panel spans the full width of the editor.
---@param winid integer
---@return "row"|"column"
local function current_form(winid)
  return vim.api.nvim_win_get_width(winid) >= vim.o.columns - 1 and "row" or "column"
end

---@param panel table
local function refit_panel(panel)
  local want = wanted_form(panel)
  if want == nil then
    return
  end

  if want == current_form(panel.winid) then
    return panel:resize()
  end

  -- diffview only reads win_config when a panel opens, so a side change needs
  -- the window torn down and split again.
  local focused = panel:is_focused()
  panel:close()
  panel:open()
  if focused then
    panel:focus()
  end
end

function M.refit()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return
  end

  local view = lib.get_current_view()
  if view == nil or view.panel == nil or not view.panel:is_open() then
    return
  end

  pcall(refit_panel, view.panel)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("harness_diff_layout", { clear = true })

  vim.api.nvim_create_autocmd({ "VimResized", "TabEnter" }, {
    group = group,
    desc = "Refit the diffview panel when the pane changes shape",
    callback = function()
      vim.schedule(M.refit)
    end,
  })
end

return M
