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

local function toggle_qf()
  local qf_winid = get_qf_winid()
  if qf_winid then
    vim.cmd("cclose")
    return
  end
  local qflist = vim.fn.getqflist()
  if vim.tbl_isempty(qflist) then
    vim.notify("Quickfix list is empty", vim.log.levels.INFO)
    return
  end
  vim.cmd(string.format("copen %d", math.min(#qflist, 10)))
end

local function toggle_loclist()
  local win = vim.api.nvim_get_current_win()
  local loc_winid = get_loc_winid(win)
  if loc_winid then
    vim.cmd("lclose")
    return
  end
  local loclist = vim.fn.getloclist(win)
  if vim.tbl_isempty(loclist) then
    vim.notify("Location list is empty", vim.log.levels.INFO)
    return
  end
  vim.cmd(string.format("lopen %d", math.min(#loclist, 10)))
end

local function next_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd("cnext")
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd("lnext")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function prev_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    vim.cmd("cprev")
  elseif is_loc_win() or get_loc_winid() then
    vim.cmd("lprev")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function smart_toggle()
  local win = vim.api.nvim_get_current_win()
  local loc_winid = get_loc_winid(win)
  local qf_winid = get_qf_winid()

  if loc_winid then
    vim.cmd("lclose")
  elseif qf_winid then
    vim.cmd("cclose")
  else
    local loclist = vim.fn.getloclist(win)
    local qflist = vim.fn.getqflist()
    if not vim.tbl_isempty(loclist) then
      vim.cmd(string.format("lopen %d", math.min(#loclist, 10)))
    elseif not vim.tbl_isempty(qflist) then
      vim.cmd(string.format("copen %d", math.min(#qflist, 10)))
    else
      vim.notify("Both quickfix and location lists are empty", vim.log.levels.INFO)
    end
  end
end

vim.keymap.set("n", "<leader>qq", toggle_qf, { desc = "Toggle quickfix" })
vim.keymap.set("n", "<leader>ql", toggle_loclist, { desc = "Toggle loclist" })
vim.keymap.set("n", "<leader>qo", smart_toggle, { desc = "Smart toggle qf/loc" })
vim.keymap.set("n", "]q", next_item, { desc = "Next qf/loc item" })
vim.keymap.set("n", "[q", prev_item, { desc = "Prev qf/loc item" })
vim.keymap.set("n", "<leader>q[", "<cmd>colder<cr>", { desc = "Older qflist" })
vim.keymap.set("n", "<leader>q]", "<cmd>cnewer<cr>", { desc = "Newer qflist" })

local augroup = vim.api.nvim_create_augroup("QuickfixConfig", { clear = true })

vim.api.nvim_create_autocmd("QuickfixCmdPost", {
  group = augroup,
  pattern = "[^l]*",
  callback = function()
    local qflist = vim.fn.getqflist()
    if not vim.tbl_isempty(qflist) and not get_qf_winid() then
      vim.cmd(string.format("copen %d", math.min(#qflist, 10)))
    end
  end,
})

vim.api.nvim_create_autocmd("QuickfixCmdPost", {
  group = augroup,
  pattern = "l*",
  callback = function()
    local loclist = vim.fn.getloclist(0)
    if not vim.tbl_isempty(loclist) and not get_loc_winid() then
      vim.cmd(string.format("lopen %d", math.min(#loclist, 10)))
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "qf",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.wrap = false
    vim.opt_local.spell = false
    vim.opt_local.cursorline = true
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, desc = "Close" })
  end,
})
