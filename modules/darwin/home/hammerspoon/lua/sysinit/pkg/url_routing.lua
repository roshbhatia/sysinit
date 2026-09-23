local M = {}
local json = require("sysinit.pkg.utils.json_loader")
local tasks = {}
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

-- Everything after the part that identifies the page. A query, a fragment, or a
-- deeper path still names the same PR or run; a bare suffix is a different page
-- wearing the same prefix, so it is not ours.
---@param suffix string
---@return boolean
local function carries(suffix)
  return suffix == "" or suffix:match("^[/#?]") ~= nil
end

-- Ordered, because `actions/runs` has to be tried before anything that would
-- also accept it.
local routes = {
  {
    kind = "pull",
    match = function(path)
      local owner, repo, number, suffix = path:match("^/([%w%-]+)/([%w_.%-]+)/pull/([1-9]%d*)(.*)$")
      if not owner or not carries(suffix) then
        return nil
      end
      return "https://github.com/" .. owner .. "/" .. repo .. "/pull/" .. number, owner .. "/" .. repo .. "#" .. number
    end,
  },
  {
    -- Only a run, because that is what `gh enhance` takes. A link to the Actions
    -- tab or to a workflow file names no run and goes to the browser instead.
    kind = "actions",
    match = function(path)
      local owner, repo, id, suffix = path:match("^/([%w%-]+)/([%w_.%-]+)/actions/runs/([1-9]%d*)(.*)$")
      if not owner or not carries(suffix) then
        return nil
      end
      return "https://github.com/" .. owner .. "/" .. repo .. "/actions/runs/" .. id,
        owner .. "/" .. repo .. " run " .. id
    end,
  },
}

---@param url string
---@return table|nil
function M.route(url)
  local scheme, authority, path = url:match("^([%a]+)://([^/]+)(/.*)$")
  if not scheme or (scheme:lower() ~= "https" and scheme:lower() ~= "http") then
    return nil
  end
  if authority:lower() ~= "github.com" then
    return nil
  end
  for _, route in ipairs(routes) do
    local canonical, label = route.match(path)
    if canonical then
      return { kind = route.kind, url = canonical, label = label }
    end
  end
  return nil
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

local function dispatch(config, target, url)
  if target.bundle then
    openBrowser(url, target.bundle)
  else
    launch(config, target.command, url)
  end
end

-- The palette the launcher already runs, so a routed link is picked in the same
-- panel as everything else rather than in a second style of list.
local function choose(config, route)
  local settings = (config.routes or {})[route.kind] or {}
  local targets = settings.targets or {}
  if #targets == 0 then
    report("No target is configured for a " .. route.kind .. " link")
    return
  end
  if #targets == 1 then
    dispatch(config, targets[1], route.url)
    return
  end
  local verb = settings.verb or "Open"
  local rows = {}
  for index, target in ipairs(targets) do
    rows[index] = {
      text = target.name,
      detail = target.detail or "",
      label = verb,
      glyph = "command",
      target = index,
    }
  end
  local spec = {
    placeholder = route.label,
    verb = verb,
    rows = rows,
    showStatus = false,
    historyKey = "github." .. route.kind,
  }
  local palette = hs.loadSpoon("CommandPalette")
  local ok = palette ~= nil
    and pcall(function()
      palette:pick(spec, function(row)
        if row then
          dispatch(config, targets[row.target], route.url)
        end
      end)
    end)
  if not ok then
    -- The palette is the launcher's, so it can be stopped or reloading. A link
    -- is still worth opening, and the first target is the one the picker would
    -- have preselected.
    report("Cannot open the " .. route.kind .. " picker")
    dispatch(config, targets[1], route.url)
  end
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
    local route = config.enable and M.route(url)
    if route then
      choose(config, route)
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
