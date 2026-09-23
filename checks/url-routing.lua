local source = assert(arg[1])
local tasks, timers, opened, alerts, registered, picks = {}, {}, {}, {}, {}, {}
local default = "org.mozilla.firefox"
local clients = {}
local focused = nil
local failedStart = false
local palette = nil
local apps = {
  [1] = "com.tinyspeck.slackmacgap",
  [2] = "org.mozilla.firefox",
  [3] = "com.google.Chrome",
  [4] = "com.apple.Safari",
}
local started = {
  pick = function(_, spec, callback)
    picks[#picks + 1] = { spec = spec, callback = callback }
  end,
}
hs = {
  printf = function() end,
  alert = {
    show = function(message)
      alerts[#alerts + 1] = message
    end,
  },
  json = {
    decode = function(text)
      assert(text == "clients", "invalid JSON")
      return clients
    end,
  },
  loadSpoon = function(name)
    assert(name == "CommandPalette", "routed a link to the wrong spoon")
    return palette
  end,
  application = {
    applicationForPID = function(pid)
      if apps[pid] then
        return {
          bundleID = function()
            return apps[pid]
          end,
        }
      end
    end,
    launchOrFocusByBundleID = function(bundle)
      focused = bundle
    end,
  },
  urlevent = {
    getDefaultHandler = function()
      return default
    end,
    setDefaultHandler = function(_, bundle)
      default = bundle or "org.hammerspoon.Hammerspoon"
      registered[#registered + 1] = default
    end,
    openURLWithBundle = function(url, bundle)
      opened[#opened + 1] = { url, bundle }
      return true
    end,
  },
  task = {
    new = function(binary, callback, args)
      local task = { binary = binary, args = args, callback = callback }
      function task:start()
        return not failedStart
      end
      function task:terminate()
        self.terminated = true
      end
      tasks[#tasks + 1] = task
      return task
    end,
  },
  timer = {
    doAfter = function(_, callback)
      local timer = { callback = callback }
      function timer:stop()
        self.stopped = true
      end
      timers[#timers + 1] = timer
      return timer
    end,
  },
}
palette = started
local environment = setmetatable({
  require = function(name)
    assert(name == "sysinit.pkg.utils.json_loader")
    return {}
  end,
}, { __index = _G })
local router = assert(loadfile(source, "t", environment))()
local dash = "/nix/store/runner/open-github-pull-gh-dash"
local editor = "/nix/store/runner/open-github-pull-neovim"
local enhance = "/nix/store/runner/open-github-actions-gh-enhance"
local config = {
  enable = true,
  browser = "org.mozilla.firefox",
  wezterm = "/nix/store/wezterm/bin/wezterm",
  weztermApp = "/nix/store/wezterm/Applications/WezTerm.app",
  home = "/Users/test user",
  routes = {
    pull = {
      verb = "Review",
      targets = {
        { name = "gh dash", detail = "Dashboard", command = dash },
        { name = "Neovim", detail = "Octo overview", command = editor },
        { name = "Firefox", detail = "github.com", bundle = "org.mozilla.firefox" },
      },
    },
    actions = {
      verb = "Watch",
      targets = {
        { name = "gh enhance", detail = "Jobs and logs", command = enhance },
        { name = "Firefox", detail = "github.com", bundle = "org.mozilla.firefox" },
      },
    },
  },
}
local pr = "https://github.com/owner/repo/pull/123"
local runUrl = "https://github.com/owner/repo/actions/runs/456"
router.setup(config)
assert(#registered == 1)
router.setup(config)
assert(#registered == 1, "reload prompted again")

for _, url in ipairs({
  pr,
  pr .. "/files",
  pr .. "#discussion_r1",
  pr .. "?q=$(touch%20/tmp/bad)",
  "HTTP://GITHUB.COM/owner/repo/pull/123",
}) do
  local route = router.route(url)
  assert(route and route.kind == "pull" and route.url == pr, url)
  assert(route.label == "owner/repo#123", url)
end
for _, url in ipairs({
  runUrl,
  runUrl .. "/job/789",
  runUrl .. "?check_suite_focus=true",
  runUrl .. "#step:3:1",
}) do
  local route = router.route(url)
  assert(route and route.kind == "actions" and route.url == runUrl, url)
  assert(route.label == "owner/repo run 456", url)
end
for _, url in ipairs({
  "https://github.com/owner/repo/issues/123",
  "https://github.com/owner/repo/pulls",
  "https://github.com/owner/repo/actions",
  "https://github.com/owner/repo/actions/workflows/ci.yml",
  "https://github.com/owner/repo/actions/runs/0",
  "https://github.com.evil.test/owner/repo/pull/123",
  "https://github.com@evil.test/owner/repo/pull/123",
  "https://evil.test@github.com/owner/repo/pull/123",
  "https://github.com:444/owner/repo/pull/123",
  pr .. "evil",
  pr .. ";touch /tmp/bad",
  runUrl .. "evil",
  "https://github.com/owner/repo/pull/0",
  "file:///owner/repo/pull/123",
  "https://github.com/owner/repo/pull/123%2Ffiles",
}) do
  assert(router.route(url) == nil, url)
end

local function click(url, pid)
  hs.urlevent.httpCallback("https", "github.com", {}, url, pid)
end
local function pick(index)
  local entry = assert(picks[#picks], "no picker was shown")
  entry.callback(index and assert(entry.spec.rows[index]) or nil)
end
local function spawned(command, url)
  return table.concat({
    "cli",
    "--no-auto-start",
    "spawn",
    "--new-window",
    "--domain-name",
    "local",
    "--workspace",
    "active session",
    "--cwd",
    config.home,
    "--",
    command,
    url,
  }, "\n")
end

for pid = 2, 4 do
  click(pr .. "/files#diff-1", pid)
  assert(opened[#opened][1] == pr .. "/files#diff-1")
  assert(opened[#opened][2] == apps[pid])
end
click("https://example.com", 1)
assert(opened[#opened][2] == config.browser)
assert(#tasks == 0, "browser links opened a terminal")
assert(#picks == 0, "browser links opened a picker")

clients = {
  { workspace = "older", idle_time = { secs = 10, nanos = 0 } },
  { workspace = "active session", idle_time = { secs = 1, nanos = 1 } },
}
click(pr .. "/files", 1)
assert(#tasks == 0, "the picker did not gate the terminal")
assert(#picks == 1)
local spec = picks[1].spec
assert(spec.placeholder == "owner/repo#123", "the picker hid which PR it reviews")
assert(spec.verb == "Review", "the pull picker lost its verb")
assert(spec.showStatus == false, "review picker shows machine status")
assert(spec.historyKey == "github.pull", "review ranking is not scoped")
assert(#spec.rows == 3)
assert(spec.rows[1].text == "gh dash", "gh dash lost the preselected row")
assert(spec.rows[1].detail == "Dashboard" and spec.rows[1].label == "Review")
assert(spec.rows[2].text == "Neovim")
assert(spec.rows[3].text == "Firefox")

pick(1)
assert(tasks[1].args[2] == "--no-auto-start")
tasks[1].callback(0, "clients", "")
assert(timers[1].stopped)
assert(table.concat(tasks[2].args, "\n") == spawned(dash, pr))
tasks[2].callback(0, "42", "")
assert(focused == "com.github.wez.wezterm")
assert(#alerts == 0)

click(pr, 1)
pick(2)
tasks[3].callback(0, "clients", "")
assert(table.concat(tasks[4].args, "\n") == spawned(editor, pr), "the editor row reused another command")
tasks[4].callback(0, "", "")

click(pr, 1)
pick(3)
assert(opened[#opened][1] == pr and opened[#opened][2] == "org.mozilla.firefox")
assert(#tasks == 4, "the browser row opened a terminal")

local quiet = #opened
click(pr, 1)
pick(nil)
assert(#tasks == 4 and #opened == quiet, "dismissing the picker launched a review")

click(runUrl .. "/job/789", 1)
local actions = picks[#picks].spec
assert(actions.placeholder == "owner/repo run 456", "the run picker hid which run it watches")
assert(actions.verb == "Watch", "the actions picker lost its verb")
assert(actions.historyKey == "github.actions", "action history shares PR ranking")
assert(#actions.rows == 2 and actions.rows[1].text == "gh enhance")
pick(1)
tasks[5].callback(0, "clients", "")
assert(table.concat(tasks[6].args, "\n") == spawned(enhance, runUrl), "a job link did not open its run in enhance")
tasks[6].callback(0, "", "")

click(runUrl, 1)
pick(2)
assert(opened[#opened][1] == runUrl and opened[#opened][2] == "org.mozilla.firefox")
assert(#tasks == 6, "the run browser row opened a terminal")

clients = {}
click(pr, 1)
pick(1)
tasks[7].callback(0, "clients", "")
assert(tasks[8].binary == "/usr/bin/open")
local expected = {
  "-n",
  "-a",
  config.weztermApp,
  "--args",
  "start",
  "--domain",
  "local",
  "--cwd",
  config.home,
  "--",
  dash,
  pr,
}
assert(table.concat(tasks[8].args, "\n") == table.concat(expected, "\n"), "cold start lost the command")
tasks[8].callback(0, "", "")

click(pr, 999)
pick(1)
tasks[9].callback(1, "", "no mux")
assert(tasks[10].binary == "/usr/bin/open")
tasks[10].callback(1, "", "launch failure")
assert(alerts[#alerts]:match("launch failure"))

click(pr, 1)
pick(1)
tasks[11].callback(0, "not JSON", "")
assert(#tasks == 11)
assert(alerts[#alerts]:match("invalid client list"))

click(pr, 1)
pick(1)
timers[#timers].callback()
assert(tasks[12].terminated)
tasks[12].callback(15, "", "terminated")
assert(#tasks == 12, "timeout started another GUI")

palette = nil
click(pr, 1)
assert(alerts[#alerts]:match("Cannot open the pull picker"))
assert(#tasks == 13, "a missing palette dropped the link")
tasks[13].callback(0, "clients", "")
tasks[14].callback(0, "", "")

palette = {
  pick = function()
    error("palette is stopped")
  end,
}
click(runUrl, 1)
assert(alerts[#alerts]:match("Cannot open the actions picker"))
assert(#tasks == 15, "a stopped palette dropped the link")
tasks[15].callback(0, "clients", "")
tasks[16].callback(0, "", "")
palette = started

failedStart = true
click(pr, 1)
pick(1)
assert(alerts[#alerts]:match("Cannot start task"))
assert(#tasks == 17)
failedStart = false

local single = #picks
config.routes.pull.targets = { { name = "gh dash", command = dash } }
click(pr, 1)
assert(#picks == single, "a single target still prompted")
assert(#tasks == 18, "a single target dropped the link")
tasks[18].callback(0, "clients", "")
tasks[19].callback(0, "", "")

config.routes.pull.targets = {}
click(pr, 1)
assert(alerts[#alerts]:match("No target is configured for a pull link"))
assert(#tasks == 19, "an empty route opened a terminal")

config.enable = false
router.setup(config)
assert(default == config.browser)
click(pr, 1)
assert(#tasks == 19 and opened[#opened][2] == config.browser, "disable lost links during handler restoration")
print(
  "URL routing: browser origins, pull and run matching, picker rows, verbs, each row, dismiss, cold start, failures, palette fallback, single target, and disable passed"
)
