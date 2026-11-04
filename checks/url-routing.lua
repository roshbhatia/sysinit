local source = assert(arg[1])
local tasks, timers, opened, alerts, registered, picks = {}, {}, {}, {}, {}, {}
local resolverTasks = {}
local resolvedTargets = {}
local default = "org.mozilla.firefox"
local focused = nil
local clipboard, clipboardWritable = nil, true
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
      if resolvedTargets[text] then
        return resolvedTargets[text]
      end
      error("invalid JSON")
    end,
  },
  loadSpoon = function(name)
    assert(name == "CommandPalette", "routed a link to the wrong spoon")
    return palette
  end,
  application = {
    runningApplications = function()
      local running = {}
      for pid, bundle in pairs(apps) do
        running[#running + 1] = {
          pid = function()
            return pid
          end,
          bundleID = function()
            return bundle
          end,
        }
      end
      return running
    end,
    launchOrFocusByBundleID = function(bundle)
      focused = bundle
    end,
  },
  pasteboard = {
    setContents = function(value)
      if not clipboardWritable then
        return false
      end
      clipboard = value
      return true
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
      function task:setCallback(callback)
        self.callback = callback
      end
      function task:start()
        return not failedStart
      end
      function task:terminate()
        self.terminated = true
      end
      if binary == "/resolver" then
        resolverTasks[#resolverTasks + 1] = task
      else
        tasks[#tasks + 1] = task
      end
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
  resolver = "/resolver",
  providerDirectory = "/providers",
  browser = "org.mozilla.firefox",
  wezterm = "/nix/store/wezterm/bin/wezterm",
  wezspawn = "/nix/store/wezspawn/bin/wezspawn",
  weztermApp = "/nix/store/wezterm/Applications/WezTerm.app",
  home = "/Users/test user",
  routes = {
    pull = {
      verb = "Review",
      providers = { "dash", "editor", "browser" },
      targets = {
        { name = "gh dash", detail = "Dashboard", command = dash },
        { name = "Neovim", detail = "Octo overview", command = editor },
        { name = "Firefox", detail = "github.com", bundle = "org.mozilla.firefox" },
      },
    },
    actions = {
      verb = "Watch",
      providers = { "enhance", "browser" },
      targets = {
        { name = "gh enhance", detail = "Jobs and logs", command = enhance },
        { name = "Firefox", detail = "github.com", bundle = "org.mozilla.firefox" },
      },
    },
  },
}
resolvedTargets.pull = config.routes.pull.targets
resolvedTargets.actions = config.routes.actions.targets
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
  local before = #resolverTasks
  hs.urlevent.httpCallback("https", "github.com", {}, url, pid)
  if #resolverTasks > before and not failedStart then
    local task = resolverTasks[#resolverTasks]
    assert(task.args[1] == "resolve" and task.args[2] == "/providers")
    task.callback(0, task.args[3], "")
  end
end
local function pick(index)
  local entry = assert(picks[#picks], "no picker was shown")
  entry.callback(index and assert(entry.spec.rows[index]) or nil)
end
local function spawned(command, url)
  return table.concat({
    "--wezterm",
    config.wezterm,
    "--gui-app",
    config.weztermApp,
    "--domain",
    "local",
    "--cwd",
    config.home,
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
assert(#tasks == 0 and #picks == 0, "browser links opened a picker or terminal")

click(pr .. "/files", 1)
assert(#tasks == 0 and #picks == 1, "the picker did not gate the terminal")
local spec = picks[1].spec
assert(spec.placeholder == "owner/repo#123")
assert(spec.verb == "Review" and spec.showStatus == false)
assert(spec.historyKey == "github.pull")
assert(#spec.rows == 4)
assert(spec.rows[1].text == "gh dash" and spec.rows[1].detail == "Dashboard")
assert(spec.rows[1].label == "Review" and spec.rows[2].text == "Neovim" and spec.rows[3].text == "Firefox")

assert(spec.rows[4].text == "Copy to clipboard" and spec.rows[4].label == "Copy")
assert(spec.rows[4].detail == pr)
local beforeCopy = #opened
pick(4)
assert(clipboard == pr, "copy did not use the canonical PR URL")
assert(#tasks == 0 and #opened == beforeCopy and focused == nil, "copy opened or focused an application")

pick(1)
assert(tasks[1].binary == config.wezspawn, "PR commands bypass the shared launcher")
assert(table.concat(tasks[1].args, "\n") == spawned(dash, pr))
tasks[1].callback(0, "42", "")
assert(timers[1].stopped and focused == "com.github.wez.wezterm" and #alerts == 0)

click(pr, 1)
pick(2)
assert(table.concat(tasks[2].args, "\n") == spawned(editor, pr))
tasks[2].callback(0, "", "")
click(pr, 1)
pick(3)
assert(opened[#opened][1] == pr and opened[#opened][2] == config.browser)
assert(#tasks == 2, "the browser row opened a terminal")
local quiet = #opened
click(pr, 1)
pick(nil)
assert(#tasks == 2 and #opened == quiet, "dismissing the picker launched a review")

click(runUrl .. "/job/789", 1)
local actions = picks[#picks].spec
assert(actions.placeholder == "owner/repo run 456" and actions.verb == "Watch")
assert(actions.historyKey == "github.actions" and #actions.rows == 2)
pick(1)
assert(tasks[3].binary == config.wezspawn)
assert(table.concat(tasks[3].args, "\n") == spawned(enhance, runUrl))
tasks[3].callback(0, "", "")
click(runUrl, 1)
pick(2)
assert(opened[#opened][1] == runUrl and opened[#opened][2] == config.browser and #tasks == 3)

click(pr, 999)
pick(1)
focused = nil
tasks[4].callback(1, "", "query failed")
assert(alerts[#alerts]:match("query failed"))
assert(#tasks == 4 and focused == nil, "a launcher failure started or focused another GUI")

click(pr, 1)
pick(1)
timers[#timers].callback()
assert(tasks[5].terminated)
tasks[5].callback(15, "", "terminated")
assert(#tasks == 5 and focused == nil, "timeout started another GUI")

palette = nil
click(pr, 1)
assert(alerts[#alerts]:match("Cannot open the pull picker") and #tasks == 6)
tasks[6].callback(0, "42", "")
palette = {
  pick = function()
    error("palette is stopped")
  end,
}
click(runUrl, 1)
assert(alerts[#alerts]:match("Cannot open the actions picker") and #tasks == 7)
tasks[7].callback(0, "42", "")
palette = started

failedStart = true
click(pr, 1)
assert(alerts[#alerts]:match("Cannot start task") and #tasks == 7)
failedStart = false
local single = #picks
resolvedTargets.pull = { { name = "gh dash", command = dash } }
click(pr, 1)
assert(#picks == single + 1 and #tasks == 7, "one provider hid the clipboard action")
assert(#picks[#picks].spec.rows == 2)
pick(2)
assert(clipboard == pr and #tasks == 7)
pick(1)
assert(#tasks == 8)
tasks[8].callback(0, "42", "")
resolvedTargets.pull = {}
click(pr, 1)
assert(alerts[#alerts]:match("No target is configured"))

config.enable = false
router.setup(config)
assert(default == config.browser)
click(pr, 1)
assert(opened[#opened][1] == pr and opened[#opened][2] == config.browser)
hs.urlevent.httpCallback(nil, nil, nil, "https://github.com/test/repo/pull/1", 999999)
config.enable = true
resolvedTargets.pull = {
  {
    name = "Devin Review",
    bundle = config.browser,
    url = "https://app.devin.ai/review/pinginc/configuration-service/pull/1424",
  },
}
click("https://github.com/pinginc/configuration-service/pull/1424/files", 1)
pick(1)
assert(opened[#opened][1] == resolvedTargets.pull[1].url and opened[#opened][2] == config.browser)
pick(2)
assert(
  clipboard == "https://github.com/pinginc/configuration-service/pull/1424",
  "copy used a provider-transformed URL"
)
clipboardWritable = false
local taskCount, browserCount = #tasks, #opened
pick(2)
assert(alerts[#alerts]:match("Cannot copy PR URL"))
assert(#tasks == taskCount and #opened == browserCount, "clipboard failure opened an application")
clipboardWritable = true
local beforeFailure = #opened
hs.urlevent.httpCallback("https", "github.com", {}, pr, 1)
resolverTasks[#resolverTasks].callback(1, "", "provider failed")
assert(alerts[#alerts]:match("provider failed") and #opened == beforeFailure)
hs.urlevent.httpCallback("https", "github.com", {}, pr, 1)
resolverTasks[#resolverTasks].callback(0, "not JSON", "")
assert(alerts[#alerts]:match("invalid JSON"))
print("URL routing: shared launcher, browser providers, failures and picker behavior passed")
