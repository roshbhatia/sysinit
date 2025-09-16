local M = {}

-- Utility to show a snacks.input popup relative to cursor, with context highlighting
-- opts: { prompt, default, title, conceal, on_submit }
function M.input(opts)
  local snacks_opts = {
    prompt = opts.prompt or "Input:",
    default = opts.default or "",
    relative = "cursor",
    border = "rounded",
    title = opts.title,
    conceal = opts.conceal or false,
  }
  vim.ui.input(snacks_opts, function(value)
    if opts.on_submit then opts.on_submit(value) end
  end)
end

-- Context highlighting for placeholders (e.g. <file>, <range>)
function M.highlight_buffer(buf)
  local input = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  local placeholders = { "<file>", "<range>", "<cwd>" } -- extend as needed
  local ns_id = vim.api.nvim_create_namespace("ai_terminals_placeholders")
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, placeholder in ipairs(placeholders) do
    local init = 1
    while true do
      local start_pos, end_pos = input:find(placeholder, init, true)
      if not start_pos then break end
      vim.api.nvim_buf_set_extmark(buf, ns_id, 0, start_pos - 1, {
        end_col = end_pos,
        hl_group = "@lsp.type.enum",
      })
      init = end_pos + 1
    end
  end
end

return M
