local M = {}

local RESEND_MAX_BYTES = 8192

---@type table<string,string>  agent name → last prompt
local last_prompts = {}

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

---@return string|nil
local function active()
  local _, name = require("harness.launch").pane()
  if not name then
    vim.notify("Harness: no agent pane - start one with <leader>jj", vim.log.levels.WARN)
    return nil
  end
  return name
end

local function input_for_active(action, default_text)
  local name = active()
  if not name then
    return
  end
  local marks = visual_marks(vim.api.nvim_get_current_buf())
  local label = name
  for _, agent in ipairs(require("harness.launch").all()) do
    if agent.name == name then
      label = agent.label
    end
  end
  require("harness.input").create_input({
    agent_name = label,
    action = action,
    default = default_text,
    selection_marks = marks,
    on_confirm = function(text)
      last_prompts[name] = text
      require("harness.launch").send(text, { submit = false })
    end,
  })
end

function M.toggle()
  require("harness.launch").pick()
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
  local name = active()
  if not name then
    return
  end
  local last = last_prompts[name]
  if not last or last == "" then
    vim.notify("Harness: no previous prompt for " .. name, vim.log.levels.WARN)
    return
  end
  if #last > RESEND_MAX_BYTES then
    vim.notify(
      string.format("Harness: last prompt is %d bytes (limit %d)", #last, RESEND_MAX_BYTES),
      vim.log.levels.WARN
    )
    return
  end
  require("harness.launch").send(last, { submit = false })
end

function M.kill()
  require("harness.launch").kill()
end

function M.status()
  local state = require("harness.launch").status()
  if not state.agent then
    vim.notify(string.format("Harness: no agent pane, %d available", state.available), vim.log.levels.INFO)
    return
  end
  vim.notify(string.format("Harness: %s in pane %s", state.agent, state.pane), vim.log.levels.INFO)
end

function M.add_buffer()
  if not active() then
    return
  end
  local placeholders = require("harness.placeholders")
  local text = placeholders.apply("+file")
  if not text or text == "" then
    vim.notify("Harness: current buffer has no file", vim.log.levels.WARN)
    return
  end
  require("harness.launch").send(text, { submit = false })
end

function M.send_selection()
  if not active() then
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
  require("harness.launch").send(text, { submit = false })
end

function M.review_close()
  pcall(function()
    require("harness.review").close()
  end)
end

---@return string[]
function M.review_roots()
  local ok, review = pcall(require, "harness.review")
  if not ok then
    return {}
  end
  return review.roots()
end

function M.review_pick()
  require("harness.review").pick()
end

function M.setup()
  require("harness.completion").setup()

  -- Unconditional, because the agent usually runs in a wezterm pane rather than
  -- a split this editor spawned. Keying it to a spawn meant the poll never ran
  -- in the ordinary case, and only the five edit-bus harnesses refreshed at all.
  pcall(function()
    require("harness.file_refresh").start()
  end)

  pcall(function()
    require("harness.edit_events").start()
  end)

  pcall(function()
    require("harness.notes").setup()
  end)
end

return M
