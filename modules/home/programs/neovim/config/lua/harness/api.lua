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

function M.walkthrough_clear()
  require("harness.control").clear()
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
  require("harness.instance").setup()
  require("harness.control").setup()
  require("harness.spec_watch").setup()
end

return M
