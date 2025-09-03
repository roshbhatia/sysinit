local M = {}

local function toggle_qf()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("copen")
end

local function toggle_loclist()
  local win = vim.api.nvim_get_current_win()
  local loclist = vim.fn.getloclist(win)
  if vim.tbl_isempty(loclist) then
    vim.notify("Location list is empty", vim.log.levels.INFO)
    return
  end
  if vim.fn.getwininfo(win)[1].loclist == 1 then
    vim.cmd("lclose")
  else
    vim.cmd("lopen")
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>qq", toggle_qf, {
    noremap = true,
    silent = true,
    desc = "Toggle quickfix list",
  })

  vim.keymap.set("n", "<leader>ll", toggle_loclist, {
    noremap = true,
    silent = true,
    desc = "Toggle location list",
  })
end

return M
