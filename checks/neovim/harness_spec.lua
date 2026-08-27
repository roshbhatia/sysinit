local busted = require("plenary.busted")
local assert = require("luassert")

busted.describe("harness setup", function()
  local original
  local notify

  busted.before_each(function()
    notify = vim.notify
    original = {}
    for _, name in ipairs({ "context", "completion", "file_refresh", "edit_events", "notes", "api" }) do
      original[name] = package.loaded["harness." .. name]
    end
  end)

  busted.after_each(function()
    vim.notify = notify
    for name, module in pairs(original) do
      package.loaded["harness." .. name] = module
    end
  end)

  busted.it("starts every subsystem after one subsystem fails", function()
    local calls = {}
    for _, spec in ipairs({
      { name = "context", method = "setup" },
      { name = "completion", method = "setup" },
      { name = "file_refresh", method = "start" },
      { name = "edit_events", method = "start" },
      { name = "notes", method = "setup" },
    }) do
      package.loaded["harness." .. spec.name] = {
        [spec.method] = function()
          calls[#calls + 1] = spec.name
          if spec.name == "edit_events" then
            error("expected subsystem failure")
          end
        end,
      }
    end

    local notifications = {}
    vim.notify = function(message)
      notifications[#notifications + 1] = message
    end
    package.loaded["harness.api"] = nil
    require("harness.api").setup()

    assert.are.equal("context,completion,file_refresh,edit_events,notes", table.concat(calls, ","))
    assert.are.equal(1, #notifications)
    assert.is_truthy(notifications[1]:find("edit_events", 1, true))
  end)
end)
