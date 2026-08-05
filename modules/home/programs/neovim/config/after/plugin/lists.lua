local function get_qf_winid()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      return win.winid
    end
  end
  return nil
end

local function get_loc_winid(winid)
  winid = winid or vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.loclist == 1 and win.tabnr == vim.fn.tabpagenr() then
      local loc_parent = vim.fn.getloclist(0, { filewinid = 0 }).filewinid
      if loc_parent == winid then
        return win.winid
      end
    end
  end
  return nil
end

local function is_qf_win()
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  return wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0
end

local function is_loc_win()
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  return wininfo and wininfo.loclist == 1
end

local function next_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd.cnext()
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd.lnext()
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function prev_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd.cprev()
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd.lprev()
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function first_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd.cfirst()
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd.lfirst()
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function last_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd.clast()
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd.llast()
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

-- Smart toggle: closed → open+focus; open unfocused → focus; focused → close
local function toggle_qf()
  local winid = get_qf_winid()
  if not winid then
    vim.cmd.copen()
  elseif vim.api.nvim_get_current_win() == winid then
    vim.cmd.cclose()
  else
    vim.api.nvim_set_current_win(winid)
  end
end

local function toggle_loc()
  local winid = get_loc_winid()
  if not winid then
    vim.cmd.lopen()
  elseif vim.api.nvim_get_current_win() == winid then
    vim.cmd.lclose()
  else
    vim.api.nvim_set_current_win(winid)
  end
end

Snacks.keymap.set("n", "]q", next_item,  { desc = "Next qf/loc item" })
Snacks.keymap.set("n", "[q", prev_item,  { desc = "Prev qf/loc item" })
Snacks.keymap.set("n", "]Q", last_item,  { desc = "Last qf/loc item" })
Snacks.keymap.set("n", "[Q", first_item, { desc = "First qf/loc item" })
Snacks.keymap.set("n", "<leader>eq", toggle_qf,  { desc = "Toggle quickfix" })
Snacks.keymap.set("n", "<leader>el", toggle_loc, { desc = "Toggle loclist" })
