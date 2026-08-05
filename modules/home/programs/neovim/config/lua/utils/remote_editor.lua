-- Host side of the agent-pane $EDITOR bridge (see utils/wezterm_terminal.lua).
-- An out-of-process agent pane (e.g. Claude's chat:externalEditor) invokes its
-- $EDITOR wrapper, which RPCs into this owning instance to open the file here
-- instead of nesting a fresh nvim. We open it in a new tab and touch a sentinel
-- once the buffer is closed so the wrapper can unblock and let the agent read
-- the edited file back.

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
    -- 'hidden' is on by default, so closing the window would merely hide the
    -- buffer; wipe it instead so BufWipeout fires and we can unblock the agent.
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
