local callback, direction, fail = nil, nil, false
local filter = {}
function filter:setCurrentSpace()
  return self
end
function filter:setDefaultFilter()
  return self
end
package.preload["sysinit.pkg.theme"] = function()
  return {
    getWindowSwitcherPrefs = function()
      return {}
    end,
  }
end
hs = {
  printf = function() end,
  window = {
    filter = {
      ignoreAlways = {},
      new = function()
        return filter
      end,
    },
    switcher = {
      new = function()
        return {
          next = function()
            if fail then
              error("stale window")
            end
            direction = "next"
          end,
          previous = function()
            if fail then
              error("stale window")
            end
            direction = "previous"
          end,
        }
      end,
    },
  },
  keycodes = { map = { tab = 48 } },
  eventtap = {
    event = { types = { keyDown = 1 } },
    new = function(_, cb)
      callback = cb
      return {
        start = function() end,
        isEnabled = function()
          return true
        end,
      }
    end,
  },
}
local core = dofile(arg[1])
core.setup()
assert(hs.window.filter.ignoreAlways.loginwindow)
local dispatch = assert(callback)
local flags = { cmd = true }
local event = {
  getFlags = function()
    return flags
  end,
  getKeyCode = function()
    return 48
  end,
}
assert(dispatch(event) and direction == "next")
flags.shift = true
assert(dispatch(event) and direction == "previous")
fail = true
assert(not dispatch(event), "failed switching must pass the key to macOS")
flags.shift = nil
assert(not dispatch(event))
print("window switcher fallback tests passed")
