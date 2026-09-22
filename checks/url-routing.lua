local source = assert(arg[1])
local tasks, timers, opened, alerts, registered, choosers = {}, {}, {}, {}, {}, {}
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
  chooser = {
    new = function(callback)
      local chooser = { callback = callback }
      function chooser:placeholderText(text)
        self.placeholder = text
        return self
      end
      function chooser:rows(count)
        self.rowCount = count
        return self
      end
      function chooser:choices(list)
        self.choiceList = list
        return self
      end
      function chooser:show()
        self.visible = true
        return self
      end
      function chooser:delete()
        self.deleted = true
        return self
      end
      choosers[#choosers + 1] = chooser
      return chooser
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
local dash = "/nix/store/runner/open-github-pr-gh-dash"
local editor = "/nix/store/runner/open-github-pr-neovim-octo"
local config = {
  enable = true,
  browser = "org.mozilla.firefox",
  wezterm = "/nix/store/wezterm/bin/wezterm",
  weztermApp = "/nix/store/wezterm/Applications/WezTerm.app",
  home = "/Users/test user",
  reviewers = {
    { name = "gh dash", detail = "Dashboard", command = dash },
    { name = "Neovim (Octo)", detail = "Octo diff", command = editor },
    { name = "Firefox", detail = "github.com", bundle = "org.mozilla.firefox" },
  },
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
assert(router.prLabel(pr) == "owner/repo#123")
assert(router.prLabel("https://example.com") == "https://example.com")

local function click(url, pid)
  hs.urlevent.httpCallback("https", "github.com", {}, url, pid)
end
local function pick(index)
  local chooser = assert(choosers[#choosers], "no picker was shown")
  chooser.callback(index and assert(chooser.choiceList[index]) or nil)
end
local function spawned(command)
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
    pr,
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
assert(#choosers == 0, "browser links opened a picker")

clients = {
  { workspace = "older", idle_time = { secs = 10, nanos = 0 } },
  { workspace = "active session", idle_time = { secs = 1, nanos = 1 } },
}
click(pr .. "/files", 1)
assert(#tasks == 0, "the picker did not gate the terminal")
assert(#choosers == 1)
local chooser = choosers[1]
assert(chooser.visible)
assert(chooser.placeholder == "owner/repo#123", "the picker hid which PR it reviews")
assert(chooser.rowCount == 3 and #chooser.choiceList == 3)
assert(chooser.choiceList[1].text == "gh dash", "gh dash lost the preselected row")
assert(chooser.choiceList[1].subText == "Dashboard")
assert(chooser.choiceList[2].text == "Neovim (Octo)")
assert(chooser.choiceList[3].text == "Firefox")

pick(1)
assert(tasks[1].args[2] == "--no-auto-start")
tasks[1].callback(0, "clients", "")
assert(timers[1].stopped)
assert(table.concat(tasks[2].args, "\n") == spawned(dash))
tasks[2].callback(0, "42", "")
assert(focused == "com.github.wez.wezterm")
assert(#alerts == 0)

click(pr, 1)
pick(2)
tasks[3].callback(0, "clients", "")
assert(table.concat(tasks[4].args, "\n") == spawned(editor), "the editor row reused another command")
tasks[4].callback(0, "", "")

click(pr, 1)
pick(3)
assert(opened[#opened][1] == pr and opened[#opened][2] == "org.mozilla.firefox")
assert(#tasks == 4, "the browser row opened a terminal")

local quiet = #opened
click(pr, 1)
pick(nil)
assert(#tasks == 4 and #opened == quiet, "dismissing the picker launched a review")

click(pr, 1)
local stale = #choosers
click(pr, 1)
assert(choosers[stale].deleted, "the first picker stayed on screen")
assert(#choosers == stale + 1)

clients = {}
pick(1)
tasks[5].callback(0, "clients", "")
assert(tasks[6].binary == "/usr/bin/open")
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
assert(table.concat(tasks[6].args, "\n") == table.concat(expected, "\n"), "cold start lost the PR command")
tasks[6].callback(0, "", "")

click(pr, 999)
pick(1)
tasks[7].callback(1, "", "no mux")
assert(tasks[8].binary == "/usr/bin/open")
tasks[8].callback(1, "", "launch failure")
assert(alerts[#alerts]:match("launch failure"))

click(pr, 1)
pick(1)
tasks[9].callback(0, "not JSON", "")
assert(#tasks == 9)
assert(alerts[#alerts]:match("invalid client list"))

click(pr, 1)
pick(1)
timers[#timers].callback()
assert(tasks[10].terminated)
tasks[10].callback(15, "", "terminated")
assert(#tasks == 10, "timeout started another GUI")

local created = hs.chooser.new
hs.chooser.new = function()
  return nil
end
click(pr, 1)
assert(alerts[#alerts]:match("Cannot create the review picker"))
assert(#tasks == 11, "a missing picker dropped the link")
tasks[11].callback(0, "clients", "")
tasks[12].callback(0, "", "")
hs.chooser.new = created

failedStart = true
click(pr, 1)
pick(1)
assert(alerts[#alerts]:match("Cannot start task"))
assert(#tasks == 13)
failedStart = false

local single = #choosers
config.reviewers = { { name = "gh dash", command = dash } }
click(pr, 1)
assert(#choosers == single, "a single reviewer still prompted")
assert(#tasks == 14, "a single reviewer dropped the link")
tasks[14].callback(0, "clients", "")
tasks[15].callback(0, "", "")

config.reviewers = {}
click(pr, 1)
assert(alerts[#alerts]:match("No PR reviewer is configured"))
assert(#tasks == 15, "an empty picker opened a terminal")

config.enable = false
router.setup(config)
assert(default == config.browser)
click(pr, 1)
assert(#tasks == 15 and opened[#opened][2] == config.browser, "disable lost links during handler restoration")
print(
  "URL routing: browser origins, PR matching, picker rows, default row, editor row, browser row, dismiss, restack, cold start, failures, single reviewer, and disable passed"
)
