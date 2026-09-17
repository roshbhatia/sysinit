local root = assert(arg[1])
local count = 0
local display_env = setmetatable({
  require = function()
    return {
      decode = function()
        return { SPDisplaysDataType = {} }
      end,
    }
  end,
  io = {
    popen = function()
      count = count + 1
      return {
        read = function()
          return "{}"
        end,
        close = function() end,
      }
    end,
  },
}, { __index = _G })
local display =
  assert(loadfile(root .. "/modules/darwin/home/sketchybar/lua/sysinit/pkg/core/display.lua", "t", display_env))()
assert(display.get_y_offset() == 8)
assert(display.get_font_size(11) == 11)
assert(count == 1, "display discovery ran twice")
local mode = "invalid"
local function decode()
  if mode == "invalid" then
    error("invalid JSON")
  end
  if mode == "scalar" then
    return "scalar"
  end
  return { valid = true }
end
local loader_env = setmetatable({ hs = { json = { decode = decode } } }, { __index = _G })
local loader =
  assert(loadfile(root .. "/modules/darwin/home/hammerspoon/lua/sysinit/pkg/utils/json_loader.lua", "t", loader_env))()
local file = os.tmpname()
local handle = assert(io.open(file, "w"))
handle:write("fixture")
handle:close()
assert(loader.load_json_file(file) == nil)
mode = "scalar"
assert(loader.load_json_file(file) == nil)
mode = "valid"
assert(loader.load_json_file(file).valid)
os.remove(file)
print("Desktop contracts passed")
