local M = {}

local RESEND_MAX_BYTES = 8192

---@type table<string,string>  adapter name → last prompt
local last_prompts = {}

local function get_active_adapter()
  local session = require("harness.session")
  local registry = require("harness.registry")
  local name = session.get_active()
  if not name then
    vim.notify("Harness: no active agent — pick one with <leader>jj", vim.log.levels.WARN)
    return nil
  end
  return registry.get_by_name(name)
end

---@param buf integer
---@return {from: integer[], to: integer[], kind: string}|nil
local function visual_marks(buf)
  local from = vim.api.nvim_buf_get_mark(buf, "<")
  local to = vim.api.nvim_buf_get_mark(buf, ">")
  if from[1] == 0 and to[1] == 0 then
    return nil
  end
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end
  local kind_map = { v = "char", V = "line", ["\22"] = "block" }
  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind_map[vim.fn.visualmode()] or "char",
  }
end

local function input_for_active(action, default_text)
  local adapter = get_active_adapter()
  if not adapter then
    return
  end
  local marks = visual_marks(vim.api.nvim_get_current_buf())
  require("harness.input").create_input({
    agent_name = adapter.label or adapter.name,
    action = action,
    default = default_text,
    selection_marks = marks,
    on_confirm = function(text)
      last_prompts[adapter.name] = text
      adapter.send(text, { submit = false })
    end,
  })
end

function M.toggle()
  require("harness.picker").pick_agent()
end

function M.ask()
  local marks = visual_marks(vim.api.nvim_get_current_buf())
  local default = marks and "+selection " or "+cursor "
  input_for_active("Ask", default)
end

function M.comment()
  local marks = visual_marks(vim.api.nvim_get_current_buf())
  local default = marks and "Comment +selection " or "Comment +cursor "
  input_for_active("Comment", default)
end

function M.fix()
  input_for_active("Fix diagnostics", "Fix +diagnostics ")
end

function M.resend()
  local adapter = get_active_adapter()
  if not adapter then
    return
  end
  local last = last_prompts[adapter.name]
  if not last or last == "" then
    vim.notify("Harness: no previous prompt for " .. adapter.name, vim.log.levels.WARN)
    return
  end
  if #last > RESEND_MAX_BYTES then
    vim.notify(
      string.format("Harness: last prompt is %d bytes (limit %d)", #last, RESEND_MAX_BYTES),
      vim.log.levels.WARN
    )
    return
  end
  adapter.send(last, { submit = false })
end

function M.kill()
  require("harness.picker").kill_active()
end

function M.kill_and_pick()
  require("harness.picker").kill_and_pick()
end

function M.options()
  local name = require("harness.session").get_active()
  if not name then
    vim.notify("Harness: no active agent — pick one with <leader>jj", vim.log.levels.WARN)
    return
  end
  require("harness.options").configure(name)
end

function M.status()
  local name = require("harness.session").get_active()
  if not name then
    vim.notify("Harness: no active agent", vim.log.levels.INFO)
    return
  end
  local summary = require("harness.options").summary(name)
  local msg = summary ~= "" and (name .. "  " .. summary) or name
  vim.notify("Harness: " .. msg, vim.log.levels.INFO)
end

function M.add_buffer()
  local adapter = get_active_adapter()
  if not adapter then
    return
  end
  local placeholders = require("harness.placeholders")
  local text = placeholders.apply("+file")
  if not text or text == "" then
    vim.notify("Harness: current buffer has no file", vim.log.levels.WARN)
    return
  end
  adapter.send(text, { submit = false })
end

function M.send_selection()
  local adapter = get_active_adapter()
  if not adapter then
    return
  end
  local marks = visual_marks(vim.api.nvim_get_current_buf())
  if not marks then
    vim.notify("Harness: no visual selection", vim.log.levels.WARN)
    return
  end
  local placeholders = require("harness.placeholders")
  local context = require("harness.context")
  local state = context.from_marks(vim.api.nvim_get_current_buf(), marks)
  local text = placeholders.apply("+selection", state)
  if not text or text == "" then
    return
  end
  adapter.send(text, { submit = false })
end

--- Which tabpages hold a codediff session, and which repository each is on.
local function session_tabs()
  local tabs = {}
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return tabs
  end
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local session = lifecycle.get_session(tab)
    if session then
      tabs[tab] = session.git_root or ""
    end
  end
  return tabs
end

--- The two facts about a repository that decide how to open it: whether it holds an
--- unmerged file, and whether it holds any change at all.
local function repo_state(root, cb)
  vim.system({ "git", "-C", root, "status", "--porcelain", "--untracked-files=all" }, { text = true }, function(res)
    local unmerged, empty = false, false
    if res.code == 0 then
      local out = res.stdout or ""
      empty = out:match("%S") == nil
      for line in out:gmatch("[^\n]+") do
        local x, y = line:sub(1, 1), line:sub(2, 2)
        if x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
          unmerged = true
        end
      end
    end
    vim.schedule(function()
      cb(unmerged, empty)
    end)
  end)
end

--- Close every open codediff session, so the next open starts from a clear tab.
local function close_sessions()
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return
  end
  for tab in pairs(session_tabs()) do
    pcall(lifecycle.close, tab)
  end
end

--- Open one repository's diff, replacing whatever session is open.

--- Open the explorer over a repository with nothing changed.
---@param root string
---@return boolean opened
local function open_empty(root)
  local ok = pcall(function()
    local view = require("codediff.ui.view")
    local path = require("codediff.core.path")
    view.create({
      mode = "explorer",
      git_root = root,
      original = path.empty(),
      modified = path.empty(),
      original_revision = nil,
      modified_revision = nil,
      layout = "inline",
      explorer_data = {
        status_result = { unstaged = {}, staged = {}, conflicts = {} },
        focus_file = nil,
        pathspec = nil,
      },
    }, "")
  end)
  return ok
end

--- `group` is `{ root, files, scoped }` with absolute paths in `files`.
---@param group table
---@param on_open fun(ok: boolean)|nil
local function open_one(group, on_open)
  repo_state(group.root, function(unmerged, empty)
    close_sessions()

    -- A clean repository never reaches `:CodeDiff`, which would refuse it. A caller
    -- that already resolved the change set says so with `empty`; every other caller
    -- gets git's answer, so no entry point can reach the refusal by not knowing.
    if group.empty or (group.empty == nil and empty) then
      local opened = open_empty(group.root)
      if not opened then
        vim.notify(
          "Harness: " .. vim.fn.fnamemodify(group.root, ":t") .. " is clean, and codediff would not open it",
          vim.log.levels.WARN
        )
      end
      -- Deferred because codediff registers the session asynchronously, and the
      -- callback opens the changed-file list in the tab that registration creates.
      vim.defer_fn(function()
        if on_open then
          on_open(opened)
        end
      end, 200)
      return
    end

    local args = { "--repo", group.root }
    -- A repository with an unmerged file opens side-by-side, against the inline
    -- default.
    if unmerged then
      table.insert(args, "--side-by-side")
    end
    if group.scoped and #group.files > 0 then
      table.insert(args, "--")
      for _, path in ipairs(group.files) do
        -- Pathspecs are relative to the repository they are passed with, so the
        -- absolute path is made relative here rather than at the call site.
        local rest = path:sub(1, #group.root + 1) == group.root .. "/" and path:sub(#group.root + 2) or nil
        if rest then
          table.insert(args, rest)
        end
      end
    end

    -- Built as command arguments rather than as a string, so a path holding a space
    -- or a bracket reaches codediff as one token without an escaping rule of its own.
    if not pcall(vim.cmd, { cmd = "CodeDiff", args = args }) then
      vim.notify("Harness: codediff could not open a diff for " .. group.root, vim.log.levels.ERROR)
      if on_open then
        on_open(false)
      end
      return
    end

    -- Deferred because codediff registers the session asynchronously, and the callback
    -- opens the changed-file list in the tab that registration creates.
    vim.defer_fn(function()
      if on_open then
        on_open(true)
      end
    end, 200)
  end)
end

--- Put the review's changed files in the quickfix list and open it along the bottom.
---@param groups table[]
---@param title string
local function fill_changed_list(groups, title)
  local items = {}
  for _, group in ipairs(groups) do
    local label = vim.fn.fnamemodify(group.root, ":t")
    for _, path in ipairs(group.files) do
      table.insert(items, {
        filename = path,
        lnum = 1,
        col = 1,
        -- The repository is in the text because the filename column shows a path that
        -- is long enough to be truncated, and the repository is what tells the owner
        -- which diff a step will open.
        text = string.format("[%s] %s", label, vim.fn.fnamemodify(path, ":.")),
      })
    end
  end
  if #items == 0 then
    return
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
end

--- Open the changed-file list along the bottom of the current tab.
local function show_changed_list()
  if #vim.fn.getqflist() == 0 then
    return
  end
  local back = vim.api.nvim_get_current_win()
  pcall(vim.cmd, "botright copen 10")
  if vim.api.nvim_win_is_valid(back) then
    pcall(vim.api.nvim_set_current_win, back)
  end
end

--- What the open review covers: every group it was given, and which one is open.
---@type { groups: table[], root: string|nil, said: string|nil }
local review_state = { groups = {}, root = nil, said = nil }

--- Open a review over a set of repositories, most changed first.
local function open_review(groups, said)
  local first = groups[1]
  if first == nil then
    return
  end

  review_state = { groups = groups, root = first.root, said = said }
  fill_changed_list(groups, said)
  require("harness.review_follow").attach()

  -- The agent's notes cover every repository the review covers, not only the open
  -- one, so a step to another repository finds its notes already read.
  local note_roots = {}
  for _, group in ipairs(groups) do
    table.insert(note_roots, group.root)
  end
  require("harness.notes").attach(note_roots, function(count)
    if count > 0 then
      vim.notify(
        string.format("Harness: %d agent note%s in this review", count, count == 1 and "" or "s"),
        vim.log.levels.INFO
      )
    end
  end)

  if #groups > 1 then
    local names = {}
    for index = 2, #groups do
      table.insert(names, string.format("%s (%d)", vim.fn.fnamemodify(groups[index].root, ":t"), #groups[index].files))
    end
    said = said
      .. string.format(
        ". Open: %s. Also changed: %s. Step with ]q, or :CodeDiff --repo <path>",
        vim.fn.fnamemodify(first.root, ":t"),
        table.concat(names, ", ")
      )
  end

  open_one(first, function()
    show_changed_list()
    vim.notify(said, vim.log.levels.INFO)
  end)
end

--- Close the review: every codediff session, the follower, and the held scope.
function M.review_close()
  close_sessions()
  pcall(function()
    require("harness.review_follow").detach()
  end)
  pcall(function()
    require("harness.notes").detach()
  end)
  -- A window the owner opened over the list themselves goes with the review, since it
  -- was opened to read this review's files. The entries stay, for `:copen` later.
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      pcall(vim.api.nvim_win_close, win.winid, false)
    end
  end
  review_state = { groups = {}, root = nil, said = nil }
end

--- Whether a review is open, meaning a set of repositories is under review and one of
--- them has a session.
---@return boolean
function M.review_is_open()
  if review_state.root == nil then
    return false
  end
  return next(session_tabs()) ~= nil
end

--- Move the review to another repository, in place of the open one.
---@param where string
function M.review_repo(where)
  local gitrepo = require("utils.gitrepo")
  local path = vim.fs.normalize(vim.fn.expand(where))

  -- The innermost repository containing the path, not the first that does. A
  -- workspace that is itself a repository contains every nested one, so a first match
  -- resolves `ws/repoA/f.txt` to `ws` and the step goes nowhere.
  local found = nil
  for _, group in ipairs(review_state.groups) do
    if path == group.root or path:sub(1, #group.root + 1) == group.root .. "/" then
      if found == nil or #group.root > #found.root then
        found = group
      end
    end
  end
  if found then
    if found.root == review_state.root then
      return
    end
    review_state.root = found.root
    open_one(found, function()
      vim.notify("Harness: reviewing " .. vim.fn.fnamemodify(found.root, ":t"), vim.log.levels.INFO)
    end)
    return
  end

  gitrepo.workspace_roots(function(roots)
    local owner = gitrepo.owning_root(path, roots)
    if not owner then
      vim.notify("Harness: " .. path .. " is in no repository under the workspace", vim.log.levels.WARN)
      return
    end
    if owner == review_state.root then
      return
    end
    review_state.root = owner
    open_one({ root = owner, files = {}, scoped = false }, function()
      vim.notify("Harness: reviewing " .. vim.fn.fnamemodify(owner, ":t"), vim.log.levels.INFO)
    end)
  end)
end

--- Open a review of the workspace's changes, over every repository that has any.
function M.review_workspace()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    -- Two different empty answers, reported as two different messages. "Nothing
    -- changed" in a directory holding no repository sends the owner looking for a
    -- diff that was never possible.
    if #roots == 0 then
      vim.notify("Harness: no git repository under " .. gitrepo.workspace(), vim.log.levels.WARN)
      return
    end
    -- An empty diff is a diff.
    if #groups == 0 then
      -- The repository the owner is standing in, or the first under the workspace when
      -- the cwd is the workspace itself and holds several. A clean workspace has no
      -- "most changed" repository to prefer, so the cwd is the only signal left.
      local here = gitrepo.owning_root(vim.fs.normalize(vim.uv.cwd() or "."), roots) or roots[1]
      -- The count, not only the repository the explorer landed on.
      local said = #roots == 1 and string.format("Harness: %s is clean", vim.fn.fnamemodify(here, ":t"))
        or string.format(
          "Harness: no changes in %d repositories under %s. Showing %s",
          #roots,
          vim.fn.fnamemodify(gitrepo.workspace(), ":t"),
          vim.fn.fnamemodify(here, ":t")
        )
      open_review({ { root = here, files = {}, scoped = false, empty = true } }, said)
      return
    end
    -- Not scoped: each repository's whole working diff, which is what the full review
    -- means.
    local whole = {}
    for _, group in ipairs(groups) do
      table.insert(whole, { root = group.root, files = group.files, scoped = false })
    end
    open_review(whole, string.format("Harness: reviewing %d repositor%s", #groups, #groups == 1 and "y" or "ies"))
  end)
end

function M.setup()
  require("harness.completion").setup()

  -- Started here rather than from `session.set_active`, because the harness whose edits
  -- matter most is usually the one in its own WezTerm pane, which this Neovim never
  -- launched and cannot know about.
  pcall(function()
    require("harness.edit_events").start()
  end)
end

return M
