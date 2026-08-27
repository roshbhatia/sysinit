local M = {}
local registered = false
local augroup = "harness_completion"

local function register_source()
  if registered then
    return
  end
  registered = true

  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return
  end

  blink.add_source_provider("harness_context", {
    module = "harness.completion",
    name = "harness_context",
  })
  blink.add_filetype_source("ai_terminals_input", "harness_context")
  blink.add_filetype_source("ai_terminals_input", "path")
end

function M.setup()
  local group = vim.api.nvim_create_augroup(augroup, { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "ai_terminals_input",
    once = true,
    callback = register_source,
  })
end

local source = {}

function source.new(opts)
  return setmetatable({}, { __index = source }):_init(opts or {})
end

function source:_init(opts)
  self.opts = opts
  return self
end

function source:enabled()
  return vim.bo.filetype == "ai_terminals_input"
end

function source:get_trigger_characters()
  return { "+" }
end

function source:get_completions(_, callback)
  local items = {}
  local ok, types = pcall(require, "blink.cmp.types")
  if not ok then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end

  for _, p in ipairs(require("harness.placeholders").descriptions) do
    table.insert(items, {
      label = p.token,
      kind = types.CompletionItemKind.Variable,
      filterText = p.token:sub(2),
      insertText = p.token,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      sortText = "0" .. p.token,
      documentation = { kind = "markdown", value = string.format("**%s**\n\n%s", p.token, p.description) },
      data = { source = "harness_context", type = "placeholder" },
    })
  end

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  return function() end
end

function source:resolve(item, callback)
  callback(item)
end

M.new = source.new

return M
