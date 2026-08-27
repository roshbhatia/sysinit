local M = {}

local tool = "/usr/sbin/screencapture"
local directory = os.getenv("HOME") .. "/Desktop"

---@param index number|nil
---@return string
local function destination(index)
  local suffix = index and string.format(" %d", index) or ""
  local stem = directory .. "/Screenshot " .. os.date("%Y-%m-%d at %H.%M.%S") .. suffix
  local path = stem .. ".png"
  local copy = 2
  while hs.fs.attributes(path) ~= nil do
    path = string.format("%s %d.png", stem, copy)
    copy = copy + 1
  end
  return path
end

---@param paths string[]
local function copy(paths)
  local images = {}
  for _, path in ipairs(paths) do
    local image = hs.image.imageFromPath(path)
    if image then
      images[#images + 1] = image
    end
  end
  if #images == 0 or not hs.pasteboard.writeObjects(images) then
    hs.alert.show("Screenshot saved, but clipboard copy failed", nil, nil, 1.5)
    return
  end
  local noun = #images == 1 and "Screenshot" or string.format("%d screenshots", #images)
  hs.alert.show(noun .. " saved and copied", nil, nil, 1)
end

---@param args string[]
---@param paths string[]
local function run(args, paths)
  for _, path in ipairs(paths) do
    args[#args + 1] = path
  end
  local task = hs.task.new(tool, function(code)
    if code == 0 then
      copy(paths)
    end
  end, args)
  if task == nil then
    hs.alert.show("Screenshot could not start", nil, nil, 1.5)
    return
  end
  task:start()
end

function M.screen()
  local paths = {}
  local count = #hs.screen.allScreens()
  for index = 1, count do
    paths[index] = destination(count == 1 and nil or index)
  end
  run({}, paths)
end

function M.area()
  run({ "-i", "-s" }, { destination() })
end

function M.window()
  run({ "-i", "-W", "-o" }, { destination() })
end

---@param kind string
function M.capture(kind)
  local selected = kind:match("^%s*(.-)%s*$")
  if selected == "screen" or selected == "full" then
    M.screen()
  elseif selected == "window" then
    M.window()
  else
    M.area()
  end
end

function M.setup()
  hs.hotkey.bind({ "cmd", "shift" }, "3", M.screen)
  hs.hotkey.bind({ "cmd", "shift" }, "4", M.area)
  hs.hotkey.bind({ "cmd", "shift" }, "5", M.window)
end

return M
