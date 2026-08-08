
local M = {}

--- @param ctl string  path to a control file holding two lines: target, sentinel
function M.open(ctl)
  local lines = vim.fn.readfile(ctl)
  local target, sentinel = lines[1], lines[2]
  if not target or not sentinel then
    return
  end
  vim.schedule(function()
    vim.cmd("tabedit " .. vim.fn.fnameescape(target))
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf,
      once = true,
      callback = function()
        pcall(vim.fn.writefile, { "" }, sentinel)
      end,
    })
  end)
  return 1
end

return M
