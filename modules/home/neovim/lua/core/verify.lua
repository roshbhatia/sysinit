local M = {}

M.verifications = {}

function M.register_verification(module_name, steps)
  M.verifications[module_name] = steps
end

function M.verify_module(module_name)
  local steps = M.verifications[module_name]
  if not steps then
    vim.notify("No verification steps found for module: " .. module_name, vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "Verification steps for module: " .. module_name,
    "=====================================",
    "",
  })

  for i, step in ipairs(steps) do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
      string.format("%d. %s", i, step.desc),
      "   Command: " .. (step.command or "Manual verification required"),
      "   Expected: " .. step.expected,
      ""
    })
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_command('vsplit')
  vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), buf)
  vim.api.nvim_buf_set_name(buf, "Verification-" .. module_name)
end

return M
