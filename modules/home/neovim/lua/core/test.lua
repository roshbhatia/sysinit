local M = {}

M.tests = {}
M.health_checks = {}

function M.register_test(module_name, tests, health_checks)
  M.tests[module_name] = tests
  if health_checks then
    M.health_checks[module_name] = health_checks
  end
end

function M.run_health_check(module_name)
  local checks = M.health_checks[module_name]
  if not checks then return true end
  
  local results = {}
  for _, check in ipairs(checks) do
    local ok, result = pcall(check)
    if not ok then
      table.insert(results, {
        status = "ERROR",
        msg = "Health check failed: " .. result
      })
    else
      table.insert(results, {
        status = result.status or "OK",
        msg = result.msg or "Check passed"
      })
    end
  end
  return results
end

function M.run_interactive_test(module_name)
  local tests = M.tests[module_name]
  if not tests then
    vim.notify("No tests found for module: " .. module_name, vim.log.levels.ERROR)
    return
  end

  -- Create test results buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_get_current_win()
  
  -- Split window for results
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
  
  local function update_results()
    local lines = {
      "Interactive Test Results for " .. module_name,
      "=====================================",
      ""
    }
    
    for i, test in ipairs(tests) do
      table.insert(lines, string.format("%d. %s", i, test.desc))
      table.insert(lines, "   Command: " .. test.command)
      table.insert(lines, "   Expected: " .. test.expected)
      table.insert(lines, "   Status: " .. (test.result or M.RESULT.PENDING))
      table.insert(lines, "")
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  -- Initial display
  update_results()

  -- Register commands for test interaction
  vim.api.nvim_create_user_command("TestPass", function(opts)
    local test_num = tonumber(opts.args)
    if test_num and tests[test_num] then
      tests[test_num].result = M.RESULT.PASS
      update_results()
    end
  end, { nargs = 1 })

  vim.api.nvim_create_user_command("TestFail", function(opts)
    local test_num = tonumber(opts.args)
    if test_num and tests[test_num] then
      tests[test_num].result = M.RESULT.FAIL
      update_results()
    end
  end, { nargs = 1 })

  -- Add health checks section
  local health_results = M.run_health_check(module_name)
  local lines = {
    "Health Check Results:",
    "-------------------",
    ""
  }
  
  for _, result in ipairs(health_results) do
    table.insert(lines, string.format("[%s] %s", result.status, result.msg))
  end
  
  -- Run :checkhealth for the module if available
  if vim.fn.exists(":checkhealth") == 2 then
    vim.cmd("checkhealth " .. module_name)
  end
  
  -- Update UI with results
  update_results()
end

return M
