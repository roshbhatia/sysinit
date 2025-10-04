local M = {}

local function is_qf_win(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local wininfo = vim.fn.getwininfo(winid)[1]
  return wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0
end

local function is_loc_win(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local wininfo = vim.fn.getwininfo(winid)[1]
  return wininfo and wininfo.loclist == 1
end

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

  local qf_height = math.min(#qflist, 10)
  vim.cmd(string.format("copen %d", qf_height))
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

  local loc_height = math.min(#loclist, 10)
  vim.cmd(string.format("lopen %d", loc_height))
end

local function next_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    pcall(vim.cmd, "cnext")
  elseif is_loc_win() or get_loc_winid() then
    pcall(vim.cmd, "lnext")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function prev_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    pcall(vim.cmd, "cprev")
  elseif is_loc_win() or get_loc_winid() then
    pcall(vim.cmd, "lprev")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function first_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    pcall(vim.cmd, "cfirst")
  elseif is_loc_win() or get_loc_winid() then
    pcall(vim.cmd, "lfirst")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function last_item()
  if is_qf_win() or (get_qf_winid() and not get_loc_winid()) then
    pcall(vim.cmd, "clast")
  elseif is_loc_win() or get_loc_winid() then
    pcall(vim.cmd, "llast")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function clear_list()
  if is_qf_win() or get_qf_winid() then
    vim.fn.setqflist({})
    vim.notify("Quickfix list cleared", vim.log.levels.INFO)
    vim.cmd("cclose")
  elseif is_loc_win() or get_loc_winid() then
    vim.fn.setloclist(0, {})
    vim.notify("Location list cleared", vim.log.levels.INFO)
    vim.cmd("lclose")
  else
    vim.notify("No quickfix or location list open", vim.log.levels.INFO)
  end
end

local function smart_toggle()
  local win = vim.api.nvim_get_current_win()
  local loclist = vim.fn.getloclist(win)
  local qflist = vim.fn.getqflist()

  local loc_winid = get_loc_winid(win)
  local qf_winid = get_qf_winid()

  if loc_winid then
    vim.cmd("lclose")
    return
  elseif qf_winid then
    vim.cmd("cclose")
    return
  end

  if not vim.tbl_isempty(loclist) then
    local loc_height = math.min(#loclist, 10)
    vim.cmd(string.format("lopen %d", loc_height))
  elseif not vim.tbl_isempty(qflist) then
    local qf_height = math.min(#qflist, 10)
    vim.cmd(string.format("copen %d", qf_height))
  else
    vim.notify("Both quickfix and location lists are empty", vim.log.levels.INFO)
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>qq", toggle_qf, {
    noremap = true,
    silent = true,
    desc = "Toggle quickfix list",
  })

  vim.keymap.set("n", "<leader>ql", toggle_loclist, {
    noremap = true,
    silent = true,
    desc = "Toggle location list",
  })

  vim.keymap.set("n", "<leader>qo", smart_toggle, {
    noremap = true,
    silent = true,
    desc = "Smart toggle qf/loclist",
  })

  vim.keymap.set("n", "]q", next_item, {
    noremap = true,
    silent = true,
    desc = "Next qf/loc item",
  })

  vim.keymap.set("n", "[q", prev_item, {
    noremap = true,
    silent = true,
    desc = "Previous qf/loc item",
  })

  vim.keymap.set("n", "[Q", first_item, {
    noremap = true,
    silent = true,
    desc = "First qf/loc item",
  })

  vim.keymap.set("n", "]Q", last_item, {
    noremap = true,
    silent = true,
    desc = "Last qf/loc item",
  })

  vim.keymap.set("n", "<leader>qc", clear_list, {
    noremap = true,
    silent = true,
    desc = "Clear qf/loc list",
  })

  vim.keymap.set("n", "<leader>q[", "<cmd>colder<cr>", {
    noremap = true,
    silent = true,
    desc = "Older quickfix list",
  })

  vim.keymap.set("n", "<leader>q]", "<cmd>cnewer<cr>", {
    noremap = true,
    silent = true,
    desc = "Newer quickfix list",
  })

  local augroup = vim.api.nvim_create_augroup("QuickfixConfig", { clear = true })

  vim.api.nvim_create_autocmd("QuickfixCmdPost", {
    group = augroup,
    pattern = "[^l]*",
    callback = function()
      local qflist = vim.fn.getqflist()
      if not vim.tbl_isempty(qflist) then
        if not get_qf_winid() then
          local height = math.min(#qflist, 10)
          vim.cmd(string.format("copen %d", height))
        end
      end
    end,
    desc = "Auto-open quickfix on populate",
  })

  vim.api.nvim_create_autocmd("QuickfixCmdPost", {
    group = augroup,
    pattern = "l*",
    callback = function()
      local loclist = vim.fn.getloclist(0)
      if not vim.tbl_isempty(loclist) then
        if not get_loc_winid() then
          local height = math.min(#loclist, 10)
          vim.cmd(string.format("lopen %d", height))
        end
      end
    end,
    desc = "Auto-open loclist on populate",
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

      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = true,
        silent = true,
        desc = "Close quickfix/loclist",
      })

      vim.keymap.set("n", "<Tab>", function()
        local is_loc = is_loc_win()
        if is_loc then
          local qflist = vim.fn.getqflist()
          if not vim.tbl_isempty(qflist) then
            vim.cmd("copen")
          end
        else
          local loclist = vim.fn.getloclist(0)
          if not vim.tbl_isempty(loclist) then
            vim.cmd("lopen")
          end
        end
      end, {
        buffer = true,
        silent = true,
        desc = "Switch between qf/loclist",
      })
    end,
    desc = "Quickfix window settings",
  })
end

return M
