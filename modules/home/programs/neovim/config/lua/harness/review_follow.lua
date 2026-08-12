-- Make the open review follow the file the owner lands on.
--
-- The review covers a set of repositories and shows one at a time. So when the owner
-- opens a file that belongs to a different reviewed repository, the review moves
-- there. That is what makes the quickfix list a usable index: `]q` walks the whole
-- workspace and the diff underneath it keeps up.
--
-- Written as a buffer event rather than as a quickfix command wrapper, so `]q`, a
-- picker, `:cdo`, and a plain `:edit` all reach it. Nothing here knows about the
-- quickfix list, which is the point: the list is one caller, not the mechanism.
local M = {}

local group = nil

--- Ask the review to move to `path`, if a review is open and the path is elsewhere.
---
--- The decision of whether the path is in scope belongs to `harness.api`, which holds
--- the review's group list. This only decides that the question is worth asking.
---@param path string
local function follow(path)
  if path == "" then
    return
  end
  local ok, api = pcall(require, "harness.api")
  if not ok or not api.review_is_open() then
    return
  end
  api.review_repo(path)
end

--- Start following. Idempotent: the augroup is cleared, so a second review does not
--- get a second listener.
function M.attach()
  group = vim.api.nvim_create_augroup("harness_review_follow", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      -- Only a real file. codediff's scratch panes, the explorer, and every plugin
      -- buffer have a buftype, and following one of those would swap the session for a
      -- window the owner did not open.
      if vim.bo[args.buf].buftype ~= "" then
        return
      end
      local path = vim.api.nvim_buf_get_name(args.buf)
      -- Deferred: this fires while codediff is still building its own windows, and a
      -- swap decided from inside that would close the session that is opening.
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          follow(vim.fs.normalize(path))
        end
      end, 50)
    end,
  })
end

function M.detach()
  if group then
    pcall(vim.api.nvim_del_augroup_by_id, group)
    group = nil
  end
end

function M.is_attached()
  return group ~= nil
end

return M
