-- Review across repositories. diffview.nvim owns the diff, the file panel, and every key
-- inside it; this owns the part diffview has no notion of, which is that a workspace holds
-- eighteen repositories and a review spans several of them.
--
-- One diffview per repository, each in its own tab, because `-C` points diffview at one
-- repository and a tab is what it opens into. The illusion of a single review is held here:
-- one command opens them all, one key moves between them, and the notes attach to every
-- root at once rather than to whichever one is in front.
local M = {}

-- The repositories under review, and the tab each one was opened into.
local session = { roots = {}, tabs = {} }

-- The revision the working tree is compared against, when the reader has asked for one.
-- Held across repositories, since a review spanning several of them is read against one
-- base, and passed to diffview as the git-rev argument it already understands.
local base = nil

--- The short name a reader knows a repository by.
---@param root string
---@return string
local function name(root)
  return vim.fn.fnamemodify(root, ":t")
end

--- Whether a recorded tab is still there. A tab closed by hand is not an error, it is a
--- repository the reader is finished with.
---@param tab number|nil
---@return boolean
local function alive(tab)
  return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

--- Forget the repositories whose tabs have gone.
local function prune()
  local roots, tabs = {}, {}
  for _, root in ipairs(session.roots) do
    if alive(session.tabs[root]) then
      roots[#roots + 1] = root
      tabs[root] = session.tabs[root]
    end
  end
  session.roots, session.tabs = roots, tabs
end

--- Whether any repository is still open for review.
---@return boolean
function M.is_open()
  prune()
  return #session.roots > 0
end

--- The repositories under review, for a caller that lists commits or notes per repository.
---@return string[]
function M.roots()
  prune()
  return vim.deepcopy(session.roots)
end

--- The repository whose tab is in front, or nil.
---@return string|nil
function M.root()
  prune()
  local here = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    if session.tabs[root] == here then
      return root
    end
  end
  return session.roots[1]
end

--- Open one repository, recording the tab diffview opened it into.
---@param root string
---@param args string|nil
local function open_one(root, args)
  local rev = args or base or ""
  local ok, err = pcall(vim.cmd, string.format("DiffviewOpen -C%s %s", vim.fn.fnameescape(root), rev))
  if not ok then
    vim.notify(string.format("Review: %s would not open: %s", name(root), err), vim.log.levels.WARN)
    return
  end
  local tab = vim.api.nvim_get_current_tabpage()
  if session.tabs[root] == nil then
    session.roots[#session.roots + 1] = root
  end
  session.tabs[root] = tab
  -- Named on the tab itself, so a tabline or a statusline can say which repository this is
  -- without asking this module.
  vim.t[tab].review_repo = name(root)
end

--- Open a review over these repositories, and attach the notes to all of them at once.
--- `args` is one rev for every repository, or a rev per repository keyed by root, which
--- is what a review "since last Tuesday" needs: the same moment resolves to a different
--- commit in each repository.
---@param roots string[]
---@param args string|table<string, string>|nil
function M.open(roots, args)
  if #roots == 0 then
    return
  end
  for _, root in ipairs(roots) do
    if not alive(session.tabs[root]) then
      open_one(root, type(args) == "table" and args[root] or args)
    end
  end
  prune()
  -- The first repository, because opening several leaves the reader in the last one and the
  -- order they were asked for is the order they should be read in.
  if alive(session.tabs[session.roots[1]]) then
    vim.api.nvim_set_current_tabpage(session.tabs[session.roots[1]])
  end
  local roots_open = M.roots()
  require("harness.notes").attach(roots_open, function(count)
    if count > 0 then
      vim.notify(string.format("Review: %d repositories, %d notes", #roots_open, count), vim.log.levels.INFO)
    end
  end)
end

--- Open one commit of one repository, for a caller that has picked one out of a log.
---@param root string
---@param commit table
function M.open_revision(root, commit)
  local sha = commit and (commit.sha or commit.hash or commit.short)
  if sha == nil then
    return
  end
  -- `sha^!` is the commit against its own parent, which is what picking a commit means.
  M.open({ root }, sha .. "^!")
end

--- Move to the next repository under review, wrapping, so several repositories read as one
--- list rather than as several windows to find.
---@param step number
function M.cycle(step)
  prune()
  if #session.roots < 2 then
    return
  end
  local here = vim.api.nvim_get_current_tabpage()
  local at = 1
  for index, root in ipairs(session.roots) do
    if session.tabs[root] == here then
      at = index
    end
  end
  local next_at = (at - 1 + step) % #session.roots + 1
  local root = session.roots[next_at]
  vim.api.nvim_set_current_tabpage(session.tabs[root])
  vim.notify(string.format("Review: %s (%d of %d)", name(root), next_at, #session.roots), vim.log.levels.INFO)
end

--- Close every repository under review, and the notes with them.
function M.close()
  prune()
  local here = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    local tab = session.tabs[root]
    if alive(tab) then
      vim.api.nvim_set_current_tabpage(tab)
      pcall(vim.cmd, "DiffviewClose")
    end
  end
  session.roots, session.tabs = {}, {}
  if vim.api.nvim_tabpage_is_valid(here) then
    pcall(vim.api.nvim_set_current_tabpage, here)
  end
  pcall(function()
    require("harness.notes").detach()
  end)
end

--- Ask which repository to review. Every repository under the workspace that has a change
--- is offered, most changed first, because a workspace holding eighteen of them has no
--- single answer and the file that happens to be open is a poor guess at one.
function M.pick()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    -- Two different empty answers, reported as two different messages. "Nothing changed" in
    -- a directory holding no repository sends the reader looking for a diff that was never
    -- possible.
    if #roots == 0 then
      vim.notify("Review: no git repository under " .. gitrepo.workspace(), vim.log.levels.WARN)
      return
    end
    if #groups == 0 then
      local here = gitrepo.owning_root(vim.fs.normalize(vim.uv.cwd() or "."), roots) or roots[1]
      vim.notify(string.format("Review: nothing changed, showing %s", name(here)), vim.log.levels.INFO)
      M.open({ here })
      return
    end
    if #groups == 1 then
      M.open({ groups[1].root })
      return
    end

    local choices = { { label = string.format("All %d repositories", #groups), roots = nil } }
    for _, group in ipairs(groups) do
      choices[#choices + 1] = {
        label = string.format("%s  (%d changed)", name(group.root), #(group.files or {})),
        roots = { group.root },
      }
    end
    vim.ui.select(choices, {
      prompt = "Review",
      format_item = function(choice)
        return choice.label
      end,
    }, function(choice)
      if choice == nil then
        return
      end
      local wanted = choice.roots
      if wanted == nil then
        wanted = {}
        for _, group in ipairs(groups) do
          wanted[#wanted + 1] = group.root
        end
      end
      M.open(wanted)
    end)
  end)
end

--- Whether the tab in front belongs to the review.
---@return boolean
function M.here()
  prune()
  local tab = vim.api.nvim_get_current_tabpage()
  for _, root in ipairs(session.roots) do
    if session.tabs[root] == tab then
      return true
    end
  end
  return false
end

--- The one review key. Closes an open review, opens the repository the reader is standing
--- in when that repository has something to show, and asks only when neither is true: in a
--- workspace of eighteen repositories a picker on every press is a question already
--- answered by where the cursor is.
function M.toggle()
  if M.is_open() then
    return M.close()
  end

  local gitrepo = require("utils.gitrepo")
  local here = gitrepo.buffer_root() or gitrepo.cwd_root()
  if here == nil then
    return M.pick()
  end

  gitrepo.workspace_changes(function(groups)
    for _, group in ipairs(groups) do
      if group.root == here then
        return M.open({ here })
      end
    end
    -- The repository underfoot is clean, so the question is which of the others to read,
    -- and that is worth asking rather than guessing.
    if #groups > 0 then
      return M.pick()
    end
    vim.notify(string.format("Review: %s is clean", name(here)), vim.log.levels.INFO)
    M.open({ here })
  end)
end

--- Re-read the diff and the notes, for a review left open while the tree moved under it.
--- Every open view, not only the one in front, and through diffview's own debounced
--- update rather than through `:DiffviewRefresh`, which would need the tab in front and
--- so would move the reader on every save.
---@param opts? { quiet?: boolean }
function M.refresh(opts)
  prune()
  local ok, lib = pcall(require, "diffview.lib")
  if ok then
    for _, view in ipairs(lib.views or {}) do
      if type(view.update_files) == "function" then
        pcall(function()
          view:update_files()
        end)
      end
    end
  end
  require("harness.notes").refresh(function(count)
    if not (opts and opts.quiet) then
      vim.notify(string.format("Review: reloaded, %d notes", count), vim.log.levels.INFO)
    end
  end)
end

--- Compare the working tree back to a commit rather than to HEAD, in every repository
--- under review at once. Reopened rather than adjusted, because the rev is an argument
--- diffview reads when a view opens.
function M.set_base()
  vim.ui.input({ prompt = "Compare the working tree back to: ", default = base or "" }, function(rev)
    if rev == nil then
      return
    end
    base = rev ~= "" and rev or nil
    local roots = M.roots()
    if #roots == 0 then
      return
    end
    M.close()
    M.open(roots)
  end)
end

--- The repository this command should answer for: the one under review, else the one the
--- current file belongs to.
---@param cb fun(root: string)
local function target(cb)
  local root = M.root()
  if root then
    return cb(root)
  end
  require("utils.gitrepo").resolve(cb, { ask = true })
end

--- The commits behind what is on screen: this file's when a file is open, the repository's
--- otherwise. One key for both, since the reader wants the history of whatever they are
--- looking at and only a panel has no file to name.
function M.history()
  local path = vim.api.nvim_buf_get_name(0)
  if path ~= "" and vim.bo.buftype == "" then
    return vim.cmd(string.format("DiffviewFileHistory %s", vim.fn.fnameescape(path)))
  end
  target(function(root)
    vim.cmd(string.format("DiffviewFileHistory -C%s", vim.fn.fnameescape(root)))
  end)
end

--- Open every changed repository at once, without asking.
function M.all()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    if #groups == 0 then
      vim.notify(
        #roots == 0 and "Review: no git repository under " .. gitrepo.workspace() or "Review: nothing changed",
        vim.log.levels.INFO
      )
      return
    end
    local wanted = {}
    for _, group in ipairs(groups) do
      wanted[#wanted + 1] = group.root
    end
    M.open(wanted)
  end)
end

return M
