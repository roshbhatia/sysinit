-- Simple verification system for modules
local M = {}

-- Store verification steps for each module
M.verification_steps = {}

-- Register verification steps for a module
function M.register_verification(module_name, steps)
  M.verification_steps[module_name] = steps
end

-- Run verification for a specific module
function M.verify_module(module_name)
  local steps = M.verification_steps[module_name]
  if not steps then
    print("No verification steps registered for module: " .. module_name)
    return false
  end
  
  print("Verifying module: " .. module_name)
  for i, step in ipairs(steps) do
    print(string.format("%d. %s", i, step.desc))
    print("   Command: " .. step.command)
    print("   Expected: " .. step.expected)
    print("")
  end
  
  return true
end

-- Run verification for all modules
function M.verify_all()
  for module_name, _ in pairs(M.verification_steps) do
    M.verify_module(module_name)
    print("---")
  end
end

-- Create a command to run verification
vim.api.nvim_create_user_command("VerifyModule", function(opts)
  local module_name = opts.args
  if module_name == "" then
    print("Usage: VerifyModule <module_name> or 'all' for all modules")
    return
  end
  
  if module_name == "all" then
    M.verify_all()
  else
    M.verify_module(module_name)
  end
end, {
  nargs = '?',
  complete = function()
    local modules = {"all"}
    for module_name, _ in pairs(M.verification_steps) do
      table.insert(modules, module_name)
    end
    return modules
  end
})

return M