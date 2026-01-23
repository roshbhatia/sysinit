local M = {}
local placeholders = require("sysinit.utils.ai.placeholders")

local blink_source = {}
local blink_source_setup_done = false

function M.setup()
  if blink_source_setup_done then
    return
  end

  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return
  end

  -- Register our source provider
  blink.add_source_provider("ai_context", {
    module = "sysinit.utils.ai.completion",
    name = "ai_context",
  })

  -- Add sources to ai_terminals_input filetype
  blink.add_filetype_source("ai_terminals_input", "ai_context")
  blink.add_filetype_source("ai_terminals_input", "path")

  blink_source_setup_done = true
end

function blink_source.new(opts)
  return setmetatable({}, { __index = blink_source }):init(opts or {})
end

function blink_source:init(opts)
  self.opts = opts
  return self
end

function blink_source:enabled()
  return vim.bo.filetype == "ai_terminals_input"
end

function blink_source:get_trigger_characters()
  return { "+" }
end

function blink_source:get_completions(ctx, callback)
  local items = {}
  local types_ok, types = pcall(require, "blink.cmp.types")
  if not types_ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end

  -- Add placeholder completions
  for _, p in ipairs(placeholders.descriptions) do
    table.insert(items, {
      label = p.token,
      kind = types.CompletionItemKind.Variable,
      filterText = p.token:sub(2),
      insertText = p.token,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      sortText = "0" .. p.token,
      documentation = {
        kind = "markdown",
        value = string.format("**%s**\n\n%s", p.token, p.description),
      },
      data = { source = "ai_context", type = "placeholder" },
    })
  end

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  return function() end
end

function blink_source:resolve(item, callback)
  callback(item)
end

M.new = blink_source.new

return M
