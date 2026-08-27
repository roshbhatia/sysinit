local busted = require("plenary.busted")
local assert = require("luassert")
local missing = {}

busted.describe("harness setup", function()
  local original
  local notify

  busted.before_each(function()
    notify = vim.notify
    original = {}
    for _, name in ipairs({ "context", "completion", "file_refresh", "edit_events", "notes", "api" }) do
      local module = package.loaded["harness." .. name]
      original[name] = module == nil and missing or module
    end
  end)

  busted.after_each(function()
    vim.notify = notify
    for name, module in pairs(original) do
      if module == missing then
        package.loaded["harness." .. name] = nil
      else
        package.loaded["harness." .. name] = module
      end
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

busted.describe("WezTerm terminal bridge", function()
  local original_system
  local original_terminal

  busted.before_each(function()
    original_system = vim.system
    original_terminal = package.loaded["utils.wezterm_terminal"]
    package.loaded["utils.wezterm_terminal"] = nil
  end)

  busted.after_each(function()
    vim.system = original_system
    package.loaded["utils.wezterm_terminal"] = original_terminal
  end)

  busted.it("keeps every pane command on the existing GUI server", function()
    local calls = {}
    vim.system = function(command, options)
      calls[#calls + 1] = { command = vim.deepcopy(command), options = vim.deepcopy(options or {}) }
      local stdout = command[4] == "split-pane" and "42\n" or ""
      if command[4] == "list" then
        stdout = '[{"pane_id":42}]'
      end
      return {
        wait = function()
          return { code = 0, stdout = stdout, stderr = "" }
        end,
      }
    end

    local terminal = require("utils.wezterm_terminal")
    local pane_id = terminal.split({
      parent = 7,
      cwd = "/repo",
      percent = 35,
      side = "left",
      argv = { "codex", "--quiet" },
    })
    assert.are.equal("42", pane_id)
    assert.is_true(terminal.send_text(42, "prompt", { submit = true, paste = false }))
    assert.is_true(terminal.pane_alive(42))

    assert.are.same({
      "wezterm",
      "cli",
      "--no-auto-start",
      "split-pane",
      "--left",
      "--pane-id",
      "7",
      "--percent",
      "35",
      "--cwd",
      "/repo",
      "--",
      "codex",
      "--quiet",
    }, calls[1].command)
    assert.are.same({
      "wezterm",
      "cli",
      "--no-auto-start",
      "send-text",
      "--pane-id",
      "42",
      "--no-paste",
    }, calls[2].command)
    assert.are.equal("prompt\r", calls[2].options.stdin)
    for _, call in ipairs(calls) do
      assert.are.same({ "wezterm", "cli", "--no-auto-start" }, vim.list_slice(call.command, 1, 3))
    end
  end)
end)

busted.describe("harness pane lifecycle", function()
  local module_names = {
    "harness.launch",
    "harness.session",
    "utils.gitrepo",
    "utils.wezterm_terminal",
  }
  local loaded
  local original_parent
  local original_pane

  busted.before_each(function()
    loaded = {}
    for _, name in ipairs(module_names) do
      loaded[name] = package.loaded[name] == nil and missing or package.loaded[name]
    end
    original_parent = vim.env.WEZTERM_PANE
    original_pane = vim.g.harness_pane
  end)

  busted.after_each(function()
    vim.env.WEZTERM_PANE = original_parent
    vim.g.harness_pane = original_pane
    for name, module in pairs(loaded) do
      if module == missing then
        package.loaded[name] = nil
      else
        package.loaded[name] = module
      end
    end
  end)

  busted.it("connects launch, send, focus, and kill to one pane", function()
    local calls = {}
    local active
    package.loaded["utils.wezterm_terminal"] = {
      split = function(options)
        calls.split = options
        return "42"
      end,
      pane_alive = function(id)
        calls.alive = id
        return true
      end,
      send_text = function(id, value, options)
        calls.send = { id = id, value = value, options = options }
        return true
      end,
      activate = function(id)
        calls.activate = id
      end,
      kill = function(id)
        calls.kill = id
      end,
    }
    package.loaded["utils.gitrepo"] = {
      buffer_root = function()
        return "/repo"
      end,
      cwd_root = function()
        return nil
      end,
    }
    package.loaded["harness.session"] = {
      set_active = function(name)
        active = name
      end,
      get_active = function()
        return active
      end,
      clear_active = function()
        active = nil
      end,
    }
    package.loaded["harness.launch"] = nil
    vim.env.WEZTERM_PANE = "7"
    vim.g.harness_pane = nil

    local launch = require("harness.launch")
    assert.is_true(launch.launch({ name = "codex", command = "codex" }))
    assert.are.same({ parent = "7", cwd = "/repo", percent = 40, argv = { "codex" } }, calls.split)
    assert.are.equal("42", vim.g.harness_pane)
    assert.are.equal("codex", active)

    assert.is_true(launch.send("review this", { submit = true }))
    assert.are.same({ id = "42", value = "review this", options = { submit = true } }, calls.send)
    assert.is_true(launch.focus())
    assert.are.equal("42", calls.activate)
    launch.kill()
    assert.are.equal("42", calls.kill)
    assert.is_nil(vim.g.harness_pane)
    assert.is_nil(active)
  end)
end)
