local root = assert(arg[1], "hammerspoon root is required")

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
package.preload["sysinit.plugins.ui.launcher.fzf"] = function()
  return {}
end
package.preload["sysinit.pkg.utils.json_loader"] = function()
  return {
    load_json_file = function()
      return nil
    end,
    get_config_path = function()
      return ""
    end,
  }
end

local callback = nil
local scripts = {}
local view = { visible = false }
local alerts = {}
local bindings = {}
local copied = {}
local tasks = {}

function view:windowStyle()
  return self
end

function view:allowTextEntry()
  return self
end

function view:transparent()
  return self
end

function view:level()
  return self
end

function view:shadow()
  return self
end

function view:html()
  return self
end

function view:isVisible()
  return self.visible
end

function view:show()
  self.visible = true
  return self
end

function view:hide()
  self.visible = false
  return self
end

function view:evaluateJavaScript(script)
  scripts[#scripts + 1] = script
  return self
end

local screen = {
  frame = function()
    return { x = 0, y = 0, w = 1440, h = 900 }
  end,
}

_G.hs = {
  alert = {
    show = function(message)
      alerts[#alerts + 1] = message
    end,
  },
  configdir = root,
  drawing = { windowLevels = { modalPanel = 1 } },
  fs = {
    attributes = function()
      return nil
    end,
  },
  hotkey = {
    bind = function(mods, key, work)
      bindings[key] = { mods = mods, work = work }
    end,
  },
  image = {
    imageFromPath = function(path)
      return { path = path }
    end,
  },
  json = {
    encode = function()
      return "[]"
    end,
  },
  mouse = {
    getCurrentScreen = function()
      return screen
    end,
  },
  pasteboard = {
    writeObjects = function(images)
      copied = images
      return true
    end,
  },
  screen = {
    allScreens = function()
      return { screen, screen }
    end,
    mainScreen = function()
      return screen
    end,
    watcher = {
      new = function()
        return { start = function() end }
      end,
    },
  },
  timer = {
    doAfter = function()
      return { stop = function() end }
    end,
  },
  task = {
    new = function(tool, callback_work, args)
      local task = { tool = tool, args = args, started = false }
      function task:start()
        self.started = true
        callback_work(0, "", "")
      end
      tasks[#tasks + 1] = task
      return task
    end,
  },
  webview = {
    usercontent = {
      new = function()
        return {
          setCallback = function(_, work)
            callback = work
          end,
        }
      end,
    },
    new = function()
      return view
    end,
  },
}

local panel = require("sysinit.plugins.ui.launcher.panel")
panel.prewarm()
panel.emoji({ { cp = "x", code = "x" } })
panel.shell_commands({ "git" })

assert(callback ~= nil, "launcher callback was not registered")
callback({ body = { action = "loaded" } })

local saw_emoji = false
local saw_commands = false
for _, script in ipairs(scripts) do
  saw_emoji = saw_emoji or script:match("^setEmoji%(") ~= nil
  saw_commands = saw_commands or script:match("^setCommands%(") ~= nil
end

assert(saw_emoji, "emoji initialization was dropped before page load")
assert(saw_commands, "shell command initialization was dropped before page load")

local screenshots = require("sysinit.plugins.ui.screenshots")
screenshots.setup()
assert(bindings["3"] and bindings["4"] and bindings["5"], "screenshot hotkeys were not registered")

screenshots.screen()
assert(#tasks == 1 and tasks[1].started, "screen capture did not start")
assert(tasks[1].tool == "/usr/sbin/screencapture", "screen capture used the wrong tool")
assert(#tasks[1].args == 2, "screen capture did not allocate one path per screen")
assert(tasks[1].args[1]:match(" 1%.png$"), "first screen path lost its index")
assert(tasks[1].args[2]:match(" 2%.png$"), "second screen path lost its index")
assert(#copied == 2, "screen capture did not copy every image")
assert(alerts[#alerts] == "2 screenshots saved and copied", "screen capture reported the wrong result")

screenshots.capture(" window ")
assert(table.concat(tasks[2].args, " "):match("^%-i %-W %-o "), "window capture used the wrong flags")
screenshots.capture("area")
assert(table.concat(tasks[3].args, " "):match("^%-i %-s "), "area capture used the wrong flags")
