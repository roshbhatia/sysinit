local M = {}

M.verifications = {}

--- Register verification steps for a module
--- @param module_name string Name of the module
--- @param steps table List of verification steps
function M.register_verification(module_name, steps)
  if not module_name or type(module_name) ~= "string" then
    vim.notify("Invalid module name for verification", vim.log.levels.ERROR)
    return
  end

  if not steps or type(steps) ~= "table" then
    vim.notify("Invalid verification steps for " .. module_name, vim.log.levels.ERROR)
    return
  end

  M.verifications[module_name] = steps
end

--- Display verification steps for a module
--- @param module_name string Name of the module to verify
function M.verify_module(module_name)
  local steps = M.verifications[module_name]
  if not steps then
    vim.notify("No verification steps found for module: " .. module_name, vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "Verification Steps for: " .. module_name,
    "===================================",
    ""
  }

  for i, step in ipairs(steps) do
    vim.list_extend(lines, {
      string.format("%d. %s", i, step.desc or "Unnamed step"),
      "   Command:   " .. (step.command or "N/A"),
      "   Expected:  " .. (step.expected or "No specific expectation"),
      ""
    })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create a vertical split and show the buffer
  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "Verification-" .. module_name)
  
  -- Add mapping to close buffer
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
end

--- Run interactive verification
--- @param module_name string Name of the module
function M.run_interactive_verification(module_name)
  local steps = M.verifications[module_name]
  if not steps then
    vim.notify("No verification steps found for module: " .. module_name, vim.log.levels.WARN)
    return
  end

  vim.notify("Starting interactive verification for " .. module_name, vim.log.levels.INFO)
  
  for _, step in ipairs(steps) do
    local prompt = string.format("Verification Step: %s\nCommand: %s\nExpected: %s\nPress Enter to continue...", 
      step.desc or "Unnamed step", 
      step.command or "N/A", 
      step.expected or "No specific expectation"
    )
    
    vim.fn.input(prompt)
  end
  
  vim.notify("Verification complete for " .. module_name, vim.log.levels.INFO)
end

--- List all registered verification modules
function M.list_verifications()
  local modules = vim.tbl_keys(M.verifications)
  if #modules > 0 then
    vim.notify("Registered verification modules:\n" .. table.concat(modules, ", "), vim.log.levels.INFO)
  else
    vim.notify("No verification modules registered", vim.log.levels.INFO)
  end
end

-- Add user commands
vim.api.nvim_create_user_command("VerifyModule", function(opts)
  M.verify_module(opts.args)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(M.verifications)
  end
})

vim.api.nvim_create_user_command("RunVerification", function(opts)
  M.run_interactive_verification(opts.args)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(M.verifications)
  end
})

vim.api.nvim_create_user_command("ListVerifications", function()
  M.list_verifications()
end, {})

return M
