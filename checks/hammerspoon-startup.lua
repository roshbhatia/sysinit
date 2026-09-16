local stored, pending, hidden = nil, nil, 0
local boot = "first-boot"
hs = {
  execute = function()
    return boot, true
  end,
  printf = function() end,
  settings = {
    get = function()
      return stored
    end,
    set = function(_, value)
      stored = value
    end,
  },
  timer = {
    doAfter = function(delay, callback)
      assert(delay == 15)
      pending = callback
      return {
        stop = function()
          pending = nil
        end,
      }
    end,
  },
  application = {
    runningApplications = function()
      return {
        {
          kind = function()
            return 1
          end,
          isHidden = function()
            return false
          end,
          hide = function()
            hidden = hidden + 1
          end,
        },
        {
          kind = function()
            return 0
          end,
          hide = function()
            error("background application hidden")
          end,
        },
      }
    end,
  },
}
local startup = dofile(arg[1])
startup.setup()
assert(stored == boot and pending == nil and hidden == 0)
startup.setup()
assert(pending == nil)
boot = "next-boot"
startup.setup()
assert(pending and hidden == 0)
pending()
pending = nil
assert(hidden == 1 and stored == boot)
startup.setup()
assert(pending == nil and hidden == 1)
print("startup hides once per new boot; first install and reload preserve applications")
