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

--- Open a review of only the files an agent wrote since this Neovim started.
---
--- The scope cannot come from review.nvim. `review.open()` takes no file list and
--- its only parameters are revisions, so the narrowing comes from codediff
--- underneath it, which accepts git pathspecs after `--` and re-applies them on
--- refresh. review.nvim then attaches to whichever codediff session the tabpage
--- holds, which is the seam its own `open()` uses.
---
--- The scope is a floor, never the whole truth: an edit made by a shell command
--- rather than by an edit tool writes no event, and an event older than this
--- Neovim is not in the set. So this never silently stands in for the full diff,
--- and every path out of here names how to reach it.
function M.review_touched()
  local ok_events, events = pcall(require, "harness.edit_events")
  if not ok_events then
    vim.notify("Harness: the edit-event watcher is not loaded", vim.log.levels.WARN)
    return
  end

  local files = events.touched_files()
  if #files == 0 then
    vim.notify(
      "Harness: no agent edits recorded this session — <leader>dr reviews the full diff",
      vim.log.levels.WARN
    )
    return
  end

  -- Pathspecs are relative to the repository, so a file outside it cannot be
  -- expressed as one. They are counted rather than dropped quietly: the touched set
  -- legitimately holds paths from other trees, because the log is keyed on the
  -- directory the agent ran in and the event carries an absolute path.
  local root = vim.trim(vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" }))
  if vim.v.shell_error ~= 0 or root == "" then
    vim.notify("Harness: not in a git repository, so a review cannot be scoped", vim.log.levels.WARN)
    return
  end

  local scoped, outside = {}, 0
  for _, path in ipairs(files) do
    local rest = path:sub(1, #root + 1) == root .. "/" and path:sub(#root + 2) or nil
    if rest then
      table.insert(scoped, rest)
    else
      outside = outside + 1
    end
  end

  if #scoped == 0 then
    vim.notify(
      string.format("Harness: all %d agent edit(s) are outside %s — <leader>dr reviews the full diff", outside, root),
      vim.log.levels.WARN
    )
    return
  end

  -- Built as command arguments rather than as a string, so a path holding a space
  -- or a bracket reaches codediff as one token without an escaping rule of its own.
  local ok_open = pcall(vim.cmd, { cmd = "CodeDiff", args = vim.list_extend({ "--" }, scoped) })
  if not ok_open then
    vim.notify("Harness: codediff could not open a scoped diff", vim.log.levels.ERROR)
    return
  end

  -- codediff initialises its session asynchronously, so the attach is retried the
  -- way review.nvim retries its own. Without it the diff opens with no comment
  -- layer and looks like a plain diff, which is the one outcome worth an error: a
  -- review that cannot record anything is not a review.
  -- The session is looked for rather than the attach being called blind.
  -- `_check_codediff_session` returns nothing and returns early when no session
  -- exists, so a pcall around it reports success whether it attached or did nothing,
  -- and a retry loop written that way never retries.
  local attempts = 0
  local function attach()
    attempts = attempts + 1
    local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
    if ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
      pcall(function()
        require("review")._check_codediff_session()
      end)
      return
    end
    if attempts < 5 then
      vim.defer_fn(attach, 100)
      return
    end
    vim.notify("Harness: the diff is scoped, but review.nvim did not attach to it", vim.log.levels.WARN)
  end
  vim.defer_fn(attach, 200)

  local said = string.format("Harness: review scoped to %d file(s) an agent wrote", #scoped)
  if outside > 0 then
    said = said .. string.format(", %d outside this repository omitted", outside)
  end
  vim.notify(said .. " — <leader>dr for the full diff", vim.log.levels.INFO)
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
