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
  configdir = root,
  drawing = { windowLevels = { modalPanel = 1 } },
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
  screen = {
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
