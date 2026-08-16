local M = {}

-- Where macOS 13 and later keep the System Settings panes. Each one is an app
-- extension; the .prefPane bundles still sitting in /System/Library/PreferencePanes
-- are the pre-Ventura copies and no longer open on their own.
local root = "/System/Library/ExtensionKit/Extensions"

-- The extension point a settings pane declares. Around 240 extensions live in
-- that directory and about 50 are panes, so the point is what separates them.
local point = "com.apple.Settings.extension.ui"

-- The display name is localized out of the Info.plist and into this table, so
-- the plist itself holds the bundle name for half the panes: "Menu Bar" is
-- ControlCenterSettings there, and "AppleCare & Warranty" is CoverageSettings.
local names = "Contents/Resources/InfoPlist.loctable"

-- Apple ships an index-term file per pane, which is what makes "wifi" find
-- Network and "brightness" find Displays. The page scores the terms on every
-- keystroke, so a pane carries only this many characters of them.
local terms_cap = 400

-- The two panes whose loctable holds no localized name, so the lookup above
-- falls through to the bundle name and the row reads "PowerPreferences". Both
-- are named here after the title System Settings gives them.
local unnamed = {
  ["com.apple.Battery-Settings.extension"] = "Battery",
  ["com.apple.HeadphoneSettings"] = "Headphones",
}

local rows = nil

---@param path string
---@return table|nil
local function plist(path)
  local ok, read = pcall(hs.plist.read, path)
  return ok and read or nil
end

---@param bundle string
---@return string|nil
local function terms_path(bundle)
  local dir = bundle .. "/Contents/Resources/en.lproj"
  local ok, iter, state = pcall(hs.fs.dir, dir)
  if not ok or not iter then
    return nil
  end
  for name in iter, state do
    if name:sub(-12) == ".searchTerms" then
      return dir .. "/" .. name
    end
  end
  return nil
end

-- Every pane's terms arrive as one dict of setting keys, each holding the
-- localizable strings for that setting. Only the words are wanted, so the shape
-- is walked rather than read by key, and repeats are dropped: a pane names its
-- own subject in most of its entries.
---@param bundle string
---@return string
local function terms(bundle)
  local path = terms_path(bundle)
  if path == nil then
    return ""
  end
  local read = plist(path)
  if type(read) ~= "table" then
    return ""
  end
  local seen, words, length = {}, {}, 0
  for _, entry in pairs(read) do
    for _, string_set in pairs(type(entry) == "table" and entry or {}) do
      for _, strings in ipairs(type(string_set) == "table" and string_set or {}) do
        for _, field in ipairs({ "title", "index" }) do
          for word in tostring(strings[field] or ""):gmatch("[%a][%w]+") do
            local key = word:lower()
            if not seen[key] and length < terms_cap then
              seen[key] = true
              words[#words + 1] = word
              length = length + #word + 1
            end
          end
        end
      end
    end
  end
  return table.concat(words, " ")
end

---@param bundle string
---@param info table
---@return string
local function name(bundle, info)
  local override = unnamed[info.CFBundleIdentifier]
  if override then
    return override
  end
  local localized = plist(bundle .. "/" .. names)
  local english = type(localized) == "table" and localized.en or nil
  if type(english) == "table" and english.CFBundleDisplayName then
    return english.CFBundleDisplayName
  end
  return info.CFBundleDisplayName or bundle:match("([^/]+)%.appex$") or bundle
end

---@param bundle string
---@return string|nil
local function icon(bundle)
  local image = hs.image.iconForFile(bundle)
  if image == nil then
    return nil
  end
  local ok, made = pcall(function()
    return image:setSize({ w = 24, h = 24 }):encodeAsURLString()
  end)
  return ok and made or nil
end

-- Scanned once. The panes come and go only with an OS update, which restarts
-- Hammerspoon anyway.
---@return table[]
function M.rows()
  if rows ~= nil then
    return rows
  end
  local found = {}
  local ok, iter, state = pcall(hs.fs.dir, root)
  if not ok or not iter then
    rows = found
    return rows
  end
  for entry in iter, state do
    if entry:sub(-6) == ".appex" then
      local bundle = root .. "/" .. entry
      local info = plist(bundle .. "/Contents/Info.plist")
      local attributes = type(info) == "table" and info.EXAppExtensionAttributes or nil
      local declared = type(attributes) == "table" and attributes.EXExtensionPointIdentifier or nil
      if declared == point and info.CFBundleIdentifier then
        local title = name(bundle, info)
        local index = terms(bundle)
        found[#found + 1] = {
          text = title,
          detail = "",
          label = "System Settings",
          terms = index,
          haystack = title .. " " .. index,
          icon = icon(bundle),
          kind = "pref",
          url = "x-apple.systempreferences:" .. info.CFBundleIdentifier,
        }
      end
    end
  end
  table.sort(found, function(left, right)
    return left.text < right.text
  end)
  rows = found
  return rows
end

return M
