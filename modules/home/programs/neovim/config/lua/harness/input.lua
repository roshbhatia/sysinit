local M = {}

local placeholders = require("harness.placeholders")
local context = require("harness.context")

---@param opts {agent_name?:string, action?:string, default?:string, selection_marks?:table, on_confirm?:fun(text:string)}
function M.create_input(opts)
  opts = opts or {}
  local agent_label = opts.agent_name or "agent"
  local title = string.format("%s — %s", opts.action or "Ask", agent_label)

  local initial_state
  if opts.selection_marks then
    initial_state = context.from_marks(vim.api.nvim_get_current_buf(), opts.selection_marks)
  else
    initial_state = context.new()
  end

  local function on_value(value)
    if not opts.on_confirm or not value or value == "" then
      return
    end
    opts.on_confirm(placeholders.apply(value, initial_state))
  end

  local snacks_ok, snacks = pcall(require, "snacks")
  if snacks_ok and snacks.input and type(snacks.input) == "function" then
    snacks.input({
      prompt = title,
      default = opts.default or "",
      win = {
        bo = { filetype = "ai_terminals_input" },
      },
    }, on_value)
    return
  end

  vim.ui.input({
    prompt = title .. ": ",
    default = opts.default or "",
  }, on_value)
end

return M
