local M = {}
local context = require("sysinit.plugins.intellicode.ai.context")

local blink_source = {}

function blink_source.new(opts)
  return setmetatable({}, { __index = blink_source }):init(opts or {})
end

function blink_source:init(opts)
  self.opts = opts
  return self
end

function blink_source:enabled()
  local ft = vim.bo.filetype
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
  return ft == "snacks_input" or buftype == "prompt"
end

function blink_source:get_trigger_characters()
  return { "@" }
end

function blink_source:get_completions(ctx, callback)
  local items = {}
  local types_ok, types = pcall(require, "blink.cmp.types")
  if not types_ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end
  for _, p in ipairs(context.placeholder_descriptions) do
    table.insert(items, {
      label = p.token,
      kind = types.CompletionItemKind.Enum,
      filterText = p.token,
      insertText = p.token,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      documentation = {
        kind = "markdown",
        value = string.format("`%s`\n\n%s", p.token, p.description),
      },
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
