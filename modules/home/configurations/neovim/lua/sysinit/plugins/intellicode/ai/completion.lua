local M = {}

function M.new(opts)
  local context = require("sysinit.plugins.intellicode.ai.context")

  local self = setmetatable({}, { __index = M })
  self.opts = opts or {}
  self.context = context
  return self
end

function M:enabled()
  return vim.bo.filetype == "ai_terminals_input"
end

function M:get_trigger_characters()
  return { "@" }
end

function M:get_completions(ctx, callback)
  local items = {}
  local types_ok, types = pcall(require, "blink.cmp.types")
  if not types_ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end

  for _, p in ipairs(self.context.placeholder_descriptions) do
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

function M:resolve(item, callback)
  callback(item)
end

return M
