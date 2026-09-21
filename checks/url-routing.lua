local source = assert(arg[1])
local tasks, timers, opened, alerts, registered = {}, {}, {}, {}, {}
local default = "org.mozilla.firefox"
local clients = {}
local focused = nil
local failedStart = false
local apps = {
  [1] = "com.tinyspeck.slackmacgap",
  [2] = "org.mozilla.firefox",
  [3] = "com.google.Chrome",
  [4] = "com.apple.Safari",
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
local environment = setmetatable({
  require = function(name)
    assert(name == "sysinit.pkg.utils.json_loader")
    return {}
  end,
}, { __index = _G })
local router = assert(loadfile(source, "t", environment))()
local config = {
  enable = true,
  browser = "org.mozilla.firefox",
  wezterm = "/nix/store/wezterm/bin/wezterm",
  weztermApp = "/nix/store/wezterm/Applications/WezTerm.app",
  home = "/Users/test user",
  command = "/nix/store/runner/open-github-pr",
}
local pr = "https://github.com/owner/repo/pull/123"
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
  assert(router.prURL(url) == pr, url)
end
for _, url in ipairs({
  "https://github.com/owner/repo/issues/123",
  "https://github.com/owner/repo/pulls",
  "https://github.com.evil.test/owner/repo/pull/123",
  "https://github.com@evil.test/owner/repo/pull/123",
  "https://evil.test@github.com/owner/repo/pull/123",
  "https://github.com:444/owner/repo/pull/123",
  pr .. "evil",
  pr .. ";touch /tmp/bad",
  "https://github.com/owner/repo/pull/0",
  "file:///owner/repo/pull/123",
  "https://github.com/owner/repo/pull/123%2Ffiles",
}) do
  assert(router.prURL(url) == nil, url)
end

local function click(url, pid)
  hs.urlevent.httpCallback("https", "github.com", {}, url, pid)
end
for pid = 2, 4 do
  click(pr .. "/files#diff-1", pid)
  assert(opened[#opened][1] == pr .. "/files#diff-1")
  assert(opened[#opened][2] == apps[pid])
end
click("https://example.com", 1)
assert(opened[#opened][2] == config.browser)
assert(#tasks == 0, "browser links opened a terminal")

clients = {
  { workspace = "older", idle_time = { secs = 10, nanos = 0 } },
  { workspace = "active session", idle_time = { secs = 1, nanos = 1 } },
}
click(pr .. "/files", 1)
assert(tasks[1].args[2] == "--no-auto-start")
tasks[1].callback(0, "clients", "")
assert(timers[1].stopped)
local expected = {
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
  config.command,
  pr,
}
assert(table.concat(tasks[2].args, "\n") == table.concat(expected, "\n"))
tasks[2].callback(0, "42", "")
assert(focused == "com.github.wez.wezterm")
assert(#alerts == 0)

clients = {}
click(pr, -1)
tasks[3].callback(0, "clients", "")
assert(tasks[4].binary == "/usr/bin/open")
expected = {
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
  config.command,
  pr,
}
assert(table.concat(tasks[4].args, "\n") == table.concat(expected, "\n"), "cold start lost the PR command")
tasks[4].callback(0, "", "")

click(pr, 999)
tasks[5].callback(1, "", "no mux")
assert(tasks[6].binary == "/usr/bin/open")
tasks[6].callback(1, "", "launch failure")
assert(alerts[#alerts]:match("launch failure"))

click(pr, 1)
tasks[7].callback(0, "not JSON", "")
assert(#tasks == 7)
assert(alerts[#alerts]:match("invalid client list"))

click(pr, 1)
timers[#timers].callback()
assert(tasks[8].terminated)
tasks[8].callback(15, "", "terminated")
assert(#tasks == 8, "timeout started another GUI")

failedStart = true
click(pr, 1)
assert(alerts[#alerts]:match("Cannot start task"))
assert(#tasks == 9)

config.enable = false
router.setup(config)
assert(default == config.browser)
click(pr, 1)
assert(#tasks == 9 and opened[#opened][2] == config.browser, "disable lost links during handler restoration")
print("URL routing: browser origins, PR matching, workspace, local domain, cold start, failures, and disable passed")
