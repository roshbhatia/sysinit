local M = {}
local json = require("sysinit.pkg.utils.json_loader")
local tasks = {}
local picker = nil
local browsers = {
  ["org.mozilla.firefox"] = true,
  ["org.mozilla.firefoxdeveloperedition"] = true,
  ["org.mozilla.nightly"] = true,
  ["com.google.Chrome"] = true,
  ["com.google.Chrome.beta"] = true,
  ["com.google.Chrome.dev"] = true,
  ["com.google.Chrome.canary"] = true,
  ["com.apple.Safari"] = true,
  ["com.apple.SafariTechnologyPreview"] = true,
}

local function report(message)
  hs.printf("URL routing: %s", message)
  hs.alert.show("URL routing: " .. message)
end

local function run(binary, args, callback)
  local task, timer
  local timedOut = false
  task = hs.task.new(binary, function(code, stdout, stderr)
    if timer then
      timer:stop()
    end
    tasks[task] = nil
    if not timedOut then
      callback(code, stdout, stderr)
    end
  end, args)
  if not task then
    report("Cannot create task: " .. binary)
    return
  end
  tasks[task] = true
  if not task:start() then
    tasks[task] = nil
    report("Cannot start task: " .. binary)
    return
  end
  timer = hs.timer.doAfter(15, function()
    timedOut = true
    task:terminate()
    report("Command timed out: " .. binary)
  end)
end

function M.prURL(url)
  local scheme, authority, path = url:match("^([%a]+)://([^/]+)(/.*)$")
  if not scheme or (scheme:lower() ~= "https" and scheme:lower() ~= "http") then
    return nil
  end
  if authority:lower() ~= "github.com" then
    return nil
  end
  local owner, repo, number, suffix = path:match("^/([%w%-]+)/([%w_.%-]+)/pull/([1-9]%d*)(.*)$")
  if not owner or (suffix ~= "" and not suffix:match("^[/#?]")) then
    return nil
  end
  return "https://github.com/" .. owner .. "/" .. repo .. "/pull/" .. number
end

function M.prLabel(url)
  local owner, repo, number = url:match("^https://github%.com/([%w%-]+)/([%w_.%-]+)/pull/([1-9]%d*)$")
  if not owner then
    return url
  end
  return owner .. "/" .. repo .. "#" .. number
end

local function openBrowser(url, bundle)
  if not hs.urlevent.openURLWithBundle(url, bundle) then
    report("Cannot open browser: " .. bundle)
  end
end

local function launch(config, command, url)
  run(config.wezterm, { "cli", "--no-auto-start", "list-clients", "--format", "json" }, function(code, stdout)
    local clients = {}
    if code == 0 then
      local ok, decoded = pcall(hs.json.decode, stdout)
      if not ok or type(decoded) ~= "table" then
        report("WezTerm returned an invalid client list")
        return
      end
      clients = decoded
    end
    table.sort(clients, function(a, b)
      local first, second = a.idle_time or {}, b.idle_time or {}
      if first.secs == second.secs then
        return (first.nanos or 0) < (second.nanos or 0)
      end
      return (first.secs or 0) < (second.secs or 0)
    end)
    if #clients == 0 then
      run("/usr/bin/open", {
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
        command,
        url,
      }, function(result, _, stderr)
        if result ~= 0 then
          report("Cannot start WezTerm: " .. stderr)
        end
      end)
      return
    end
    run(config.wezterm, {
      "cli",
      "--no-auto-start",
      "spawn",
      "--new-window",
      "--domain-name",
      "local",
      "--workspace",
      clients[1].workspace,
      "--cwd",
      config.home,
      "--",
      command,
      url,
    }, function(result, _, stderr)
      if result ~= 0 then
        report("Cannot open PR window: " .. stderr)
        return
      end
      hs.application.launchOrFocusByBundleID("com.github.wez.wezterm")
    end)
  end)
end

local function dispatch(config, reviewer, url)
  if reviewer.bundle then
    openBrowser(url, reviewer.bundle)
  else
    launch(config, reviewer.command, url)
  end
end

local function choose(config, url)
  local reviewers = config.reviewers or {}
  if #reviewers == 0 then
    report("No PR reviewer is configured")
    return
  end
  if #reviewers == 1 then
    dispatch(config, reviewers[1], url)
    return
  end
  -- A second link must not leave the first picker orphaned on screen.
  if picker then
    picker:delete()
    picker = nil
  end
  local choices = {}
  for index, reviewer in ipairs(reviewers) do
    choices[index] = { text = reviewer.name, subText = reviewer.detail, reviewer = index }
  end
  picker = hs.chooser.new(function(choice)
    picker = nil
    if choice then
      dispatch(config, reviewers[choice.reviewer], url)
    end
  end)
  if not picker then
    report("Cannot create the review picker")
    dispatch(config, reviewers[1], url)
    return
  end
  picker:placeholderText(M.prLabel(url))
  picker:rows(#choices)
  picker:choices(choices)
  picker:show()
end

function M.setup(config)
  config = config or json.load_json_file(json.get_config_path("url_routing.json"))
  if not config then
    return
  end
  hs.urlevent.httpCallback = function(_, _, _, url, senderPID)
    local app = senderPID and senderPID > 0 and hs.application.applicationForPID(senderPID)
    local sender = app and app:bundleID()
    if browsers[sender] then
      openBrowser(url, sender)
      return
    end
    local pr = config.enable and M.prURL(url)
    if pr then
      choose(config, pr)
    else
      openBrowser(url, config.browser)
    end
  end
  local handler = hs.urlevent.getDefaultHandler("https")
  if config.enable and handler ~= "org.hammerspoon.Hammerspoon" then
    hs.urlevent.setDefaultHandler("https")
  elseif not config.enable and handler == "org.hammerspoon.Hammerspoon" then
    hs.urlevent.setDefaultHandler("https", config.browser)
  end
end

return M
