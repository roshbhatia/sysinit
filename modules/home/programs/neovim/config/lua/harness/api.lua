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

--- Close the review, and the follower and notes it attached.
function M.review_close()
  pcall(function()
    require("review").close()
  end)
  pcall(function()
    require("harness.notes").detach()
  end)
end

--- The repository the open review is on, as a list, for a caller that lists commits per
--- repository. Empty when no review is open.
---@return string[]
function M.review_roots()
  local ok, review = pcall(require, "review")
  if not ok or not review.is_open() then
    return {}
  end
  local root = review.root()
  return root and { root } or {}
end

--- Whether a review is open.
---@return boolean
function M.review_is_open()
  local ok, review = pcall(require, "review")
  return ok and review.is_open()
end

--- Pick a repository to review and open it. Every repository under the workspace that has
--- a change is offered, most changed first, because a workspace holding eighteen of them
--- has no single answer and the file that happens to be open is a poor guess at one.
function M.review_pick()
  local gitrepo = require("utils.gitrepo")
  gitrepo.workspace_changes(function(groups, roots)
    -- Two different empty answers, reported as two different messages. "Nothing changed"
    -- in a directory holding no repository sends the owner looking for a diff that was
    -- never possible.
    if #roots == 0 then
      vim.notify("Harness: no git repository under " .. gitrepo.workspace(), vim.log.levels.WARN)
      return
    end
    local review = require("review")
    if #groups == 0 then
      -- The repository the owner is standing in, or the first under the workspace. A
      -- clean workspace has no most-changed repository to prefer.
      local here = gitrepo.owning_root(vim.fs.normalize(vim.uv.cwd() or "."), roots) or roots[1]
      vim.notify(
        #roots == 1 and string.format("Harness: %s is clean", vim.fn.fnamemodify(here, ":t"))
          or string.format("Harness: no changes in %d repositories, showing %s", #roots, vim.fn.fnamemodify(here, ":t")),
        vim.log.levels.INFO
      )
      review.open(here)
      return
    end
    if #groups == 1 then
      review.open(groups[1].root)
      return
    end
    vim.ui.select(groups, {
      prompt = "Review which repository?",
      format_item = function(group)
        return string.format("%s  (%d changed)", vim.fn.fnamemodify(group.root, ":t"), #group.files)
      end,
    }, function(group)
      if group then
        review.open(group.root)
      end
    end)
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
