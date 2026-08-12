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

function M.send_review()
  local adapter = get_active_adapter()
  if not adapter then
    return
  end
  local ok_store, store = pcall(require, "review.store")
  local ok_export, export = pcall(require, "review.export")
  if not (ok_store and ok_export) then
    vim.notify("Harness: review.nvim not loaded — open a review with <leader>dr", vim.log.levels.WARN)
    return
  end
  local count = store.count()
  if count == 0 then
    vim.notify("Harness: no review comments to send", vim.log.levels.WARN)
    return
  end
  local markdown = export.generate_markdown()
  last_prompts[adapter.name] = markdown
  adapter.send(markdown, { submit = false })
  vim.notify(string.format("Harness: sent %d review comment(s) to %s", count, adapter.name), vim.log.levels.INFO)
end

--- Which tabpages hold a codediff session, and which repository each is on.
---
--- The one place that reads codediff's session registry, so its shape is asserted
--- once rather than at every call site that needs to know where a diff went.
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

--- Whether a repository holds a file git reports as unmerged, called back with a
--- boolean. Answers false when git cannot say.
---
--- Asked of git rather than read out of the changed-file list, so this stays a
--- yes-or-no question about one repository and does not depend on the format the
--- list arrived in.
local function has_conflict(root, cb)
  vim.system({ "git", "-C", root, "diff", "--name-only", "--diff-filter=U" }, { text = true }, function(res)
    local unmerged = res.code == 0 and (res.stdout or ""):match("%S") ~= nil
    vim.schedule(function()
      cb(unmerged)
    end)
  end)
end

--- Close every open codediff session, so the next open starts from a clear tab.
---
--- `:CodeDiff` is a toggle at its entry point: issued from a tab that already holds a
--- session it closes that session and opens nothing (`codediff/commands.lua:930`).
--- Closing through `lifecycle` instead says what is meant, and does not depend on
--- which tab the cursor is in when it runs.
local function close_sessions()
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return
  end
  for tab in pairs(session_tabs()) do
    pcall(lifecycle.close, tab)
  end
end

--- Attach review.nvim's comment layer to the codediff session in the current tab.
---
--- Without an attach the diff opens with no comment layer and looks like a plain
--- diff, which is the one outcome worth a warning: a review that cannot record
--- anything is not a review.
---
--- This reaches another plugin's internals. It is the existing attach seam and there
--- is no upstream API to replace it with, so it is confined to this one function and
--- reported by the health check rather than spread across the call sites.
local function attach_review()
  if not pcall(function()
    require("review")._check_codediff_session()
  end) then
    vim.notify("Harness: the diff opened, but review.nvim did not attach to it", vim.log.levels.WARN)
  end
end

--- Open one repository's diff, replacing whatever session is open.
---
--- One session at a time, which is what makes this indifferent to how many
--- repositories the workspace holds. The fan-out this replaces opened one tab per
--- repository and then had to decide which tab the owner belonged in, a question
--- codediff and review.nvim answer on their own asynchronous schedules: review.nvim
--- focuses a session's modified window 150ms after it attaches and does not check
--- that the owner is still on that tab (`review/hooks.lua:228`). Measured in a real
--- pane, that lost the race one run in three whatever this side waited for. With one
--- session there is no tab to choose.
---
--- The file scope cannot come from review.nvim. `review.open()` takes no file list
--- and its only parameters are revisions, so the narrowing comes from codediff
--- underneath it, which accepts git pathspecs after `--` and re-applies them on
--- refresh. review.nvim then attaches to whichever codediff session the tabpage
--- holds, which is the seam its own `open()` uses.
---
--- `group` is `{ root, files, scoped }` with absolute paths in `files`. `scoped`
--- false means the whole working diff of that repository.
---@param group table
---@param on_open fun(ok: boolean)|nil
local function open_one(group, on_open)
  has_conflict(group.root, function(unmerged)
    close_sessions()

    local args = { "--repo", group.root }
    -- A repository with an unmerged file opens side-by-side, against the inline
    -- default. codediff sends a conflicted file to its three-pane merge view, which
    -- needs both panes to already exist: `side_by_side.update` rebuilds a pane that
    -- was closed but not an inline session's single one, so an inline session showed
    -- one side of the conflict with no result pane and no accept keymaps.
    -- `<leader>dl` still toggles it back.
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

    -- The attach is deferred because codediff registers the session asynchronously and
    -- review.nvim reads the current tabpage to decide what it is attaching to. It also
    -- attaches on `TabEnter` by itself (`review/init.lua:27`), so this is the first of
    -- two chances rather than the only one.
    vim.defer_fn(function()
      attach_review()
      if on_open then
        on_open(true)
      end
    end, 200)
  end)
end

--- Put the review's changed files in the quickfix list, most changed repository
--- first, and open nothing.
---
--- The list is the cross-repository index, because a changed file's path is absolute
--- and so a list of them does not care how many repositories they came from. It is
--- the quickfix list rather than a buffer of this feature's own so that `:cdo`, `]q`,
--- and any quickfix renderer already read it, knowing nothing about reviews.
---
--- Within a repository codediff's explorer stays the index. The two do not compete:
--- this one crosses roots, that one crosses files in one root.
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

--- What the open review covers: every group it was given, and which one is open.
---
--- Held so that stepping to another repository keeps the review's own scope. Without
--- it, a step out of a scoped review and back would silently widen to the whole
--- working diff, which is the same file set the review deliberately narrowed.
---@type { groups: table[], root: string|nil, said: string|nil }
local review_state = { groups = {}, root = nil, said = nil }

--- Open a review over a set of repositories, most changed first.
---
--- The first is opened. The rest are named, with the count and the command that
--- reaches one, because a review that silently covered two of seven repositories
--- would read as a clean workspace.
---
--- `groups` is a list of `{ root, files, scoped }`, already sorted by the caller.
local function open_review(groups, said)
  local first = groups[1]
  if first == nil then
    return
  end

  review_state = { groups = groups, root = first.root, said = said }
  fill_changed_list(groups, said)
  require("harness.review_follow").attach()

  -- Only a review that spans repositories shows the list. For one repository
  -- codediff's explorer is already the file index, and a second one beside it would
  -- say nothing new.
  local span = #groups > 1
  if span then
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
    -- The generic `]q` in `after/plugin/lists.lua` steps a list only while its window
    -- is open, and refuses with "No quickfix or location list open" when it is not.
    -- So the message above is true only if the review opens it. Focus goes straight
    -- back, because the diff is what the owner asked for.
    if span then
      local diff_win = vim.api.nvim_get_current_win()
      pcall(vim.cmd, "botright copen")
      if vim.api.nvim_win_is_valid(diff_win) then
        pcall(vim.api.nvim_set_current_win, diff_win)
      end
    end
    vim.notify(said, vim.log.levels.INFO)
  end)
end

--- Close the review: every codediff session, the follower, and the held scope.
---
--- Called before a session manager saves the layout, because a diff tab is a view
--- rather than a layout worth restoring. Saved, it returns as an empty tab, and one
--- accumulated per review: measured over five consecutive reviews of the same
--- workspace, the tab count on start went 2, 3, 4, 5, 6.
---
--- Safe to call when nothing is open, which is what lets the caller be a blunt
--- "before save" hook rather than something that has to know the review's state.
function M.review_close()
  close_sessions()
  pcall(function()
    require("harness.review_follow").detach()
  end)
  -- The list window came with the review, so it goes with it. The entries stay: a
  -- closed quickfix list is still there for `:copen` and for `<leader>eq`.
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      pcall(vim.api.nvim_win_close, win.winid, false)
    end
  end
  review_state = { groups = {}, root = nil, said = nil }
end

--- Whether a review is open, meaning a set of repositories is under review and one of
--- them has a session.
---
--- Asked by `harness.review_follow` before it moves anything, so the follower needs no
--- copy of this module's state.
---@return boolean
function M.review_is_open()
  if review_state.root == nil then
    return false
  end
  return next(session_tabs()) ~= nil
end

--- Move the review to another repository, in place of the open one.
---
--- `where` is a repository root or any path inside one. The review's own scope for
--- that repository is reused when it has one, so stepping out of a scoped review and
--- back does not widen it to the whole working diff.
---
--- Nothing is opened when the path belongs to no repository the current query found.
--- That is a real answer: it means the review does not cover that file, and opening
--- the whole diff of somewhere else would hide it.
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
---
--- This is the full path. `review_touched` is the same code with a narrower file
--- set, which is the point: a missing edit bus lands here instead of failing.
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
    if #groups == 0 then
      vim.notify(
        string.format("Harness: nothing changed in %d repositor%s here", #roots, #roots == 1 and "y" or "ies"),
        vim.log.levels.INFO
      )
      return
    end
    -- Not scoped: each repository's whole working diff, which is what the full
    -- review means. The file list is carried anyway, because it is what orders the
    -- repositories and what the remainder message counts. Dropping it made the
    -- message say `r5 (0), r6 (0)` for repositories that had changes.
    local whole = {}
    for _, group in ipairs(groups) do
      table.insert(whole, { root = group.root, files = group.files, scoped = false })
    end
    open_review(whole, string.format("Harness: reviewing %d repositor%s", #groups, #groups == 1 and "y" or "ies"))
  end)
end

--- Open a review of only the files an agent wrote since this Neovim started.
---
--- Every way this can fail to narrow falls through to the full review rather than
--- warning and opening nothing: no watcher, no events, or events naming nothing
--- inside the workspace.
---
--- The scope is a floor, never the whole truth. An edit made by a shell command
--- rather than by an edit tool writes no event, and an event older than this Neovim
--- is not in the set. So this never silently stands in for the full diff, and every
--- path out of here says which one it took.
function M.review_touched()
  local ok_events, events = pcall(require, "harness.edit_events")
  local files = ok_events and events.touched_files() or {}

  local why = nil
  if not ok_events then
    why = "the edit-event watcher is not loaded"
  elseif #files == 0 then
    why = "no agent edits recorded this session"
  end
  if why then
    vim.notify("Harness: " .. why .. ", reviewing the full workspace diff", vim.log.levels.INFO)
    return M.review_workspace()
  end

  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_roots(function(roots)
    local groups, index, outside = {}, {}, 0
    for _, path in ipairs(files) do
      local owner = gitrepo.owning_root(path, roots)
      if owner then
        if not index[owner] then
          index[owner] = { root = owner, files = {}, scoped = true }
          table.insert(groups, index[owner])
        end
        table.insert(index[owner].files, path)
      else
        outside = outside + 1
      end
    end

    if #groups == 0 then
      vim.notify(
        string.format(
          "Harness: all %d agent edit(s) are outside this workspace, reviewing the full workspace diff",
          outside
        ),
        vim.log.levels.INFO
      )
      return M.review_workspace()
    end

    table.sort(groups, function(a, b)
      if #a.files ~= #b.files then
        return #a.files > #b.files
      end
      return a.root < b.root
    end)

    local scoped = 0
    for _, group in ipairs(groups) do
      scoped = scoped + #group.files
    end
    local said = string.format(
      "Harness: review scoped to %d file(s) an agent wrote across %d repositor%s",
      scoped,
      #groups,
      #groups == 1 and "y" or "ies"
    )
    if outside > 0 then
      said = said .. string.format(", %d outside the workspace omitted", outside)
    end
    open_review(groups, said)
  end)
end

function M.preview_spec()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Harness: current buffer has no file", vim.log.levels.WARN)
    return
  end
  local res = require("harness.preview").open(path, { focus = false })
  if not res.ok then
    vim.notify("Harness: " .. tostring(res.error), vim.log.levels.WARN)
  end
end

function M.setup()
  require("harness.completion").setup()

  -- Started here rather than from `session.set_active`, because the harness whose
  -- edits matter most is usually the one in its own WezTerm pane, which this
  -- Neovim never launched and cannot know about. A watcher that only ran for a
  -- harness toggled from inside Neovim would miss exactly the workflow this
  -- exists for.
  pcall(function()
    require("harness.edit_events").start()
  end)
end

return M
