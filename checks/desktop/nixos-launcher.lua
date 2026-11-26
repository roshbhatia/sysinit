local commands = {}
local output = ""
local context = setmetatable({
  GetEntries = function()
    return {}
  end,
  Action = "",
  os = {
    getenv = function(key)
      if key == "SWAYSOCK" then
        return "/tmp/launcher-test.sock"
      end
      return os.getenv(key)
    end,
  },
  io = {
    popen = function(command)
      commands[#commands + 1] = command
      return {
        read = function()
          return output
        end,
        close = function()
          return true
        end,
      }
    end,
  },
}, { __index = _G })

local function loadMenu(path)
  assert(loadfile(path, "t", context))()
end

output = "stable-id\tDisplay name\t2\t/project path\n"
loadMenu(arg[1])
local sessions = context.GetEntries()
assert(#sessions == 1 and sessions[1].Value == "stable-id")
assert(sessions[1].Text == "Display name" and sessions[1].Subtext == "2 repos")
assert(context.Action:find("/ty session launch %VALUE%", 1, true))
assert(commands[#commands]:find("list --json", 1, true))

output = "12\tworkspace\tEditor\t/project path\n"
loadMenu(arg[2])
local panes = context.GetEntries()
assert(#panes == 1 and panes[1].Value == "12")
assert(context.Action:find("cli --no-auto-start activate-pane", 1, true))
assert(commands[#commands]:find("cli --no-auto-start list", 1, true))

output = "Documentation\thttps://example.com\n"
loadMenu(arg[3])
local tabs = context.GetEntries()
assert(#tabs == 1 and tabs[1].Value == "https://example.com")

output = "42\tEditor\teditor\n"
loadMenu(arg[4])
local windows = context.GetEntries()
assert(#windows == 1 and windows[1].Value == "42")
