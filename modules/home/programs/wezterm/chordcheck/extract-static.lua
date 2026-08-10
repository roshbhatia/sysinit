
local layer, root = ...
if not layer or not root then
  io.stderr:write("usage: extract-static.lua <wezterm|neovim|pi> <root>\n")
  os.exit(2)
end

local function read(path)
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  local body = fh:read("*a")
  fh:close()
  return body
end

-- A chord written inside a comment is usually one the code deliberately does NOT bind.
local function uncomment(body)
  local out = {}
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    if not line:match("^%s*%-%-") then
      out[#out + 1] = line
    end
  end
  return table.concat(out, "\n")
end

local function files(dir, ext)
  local out = {}
  local pipe = io.popen(string.format("find %q -type f -name '*.%s' 2>/dev/null", dir, ext))
  if not pipe then
    return out
  end
  for line in pipe:lines() do
    out[#out + 1] = line
  end
  pipe:close()
  return out
end

local MOD_ORDER = { cmd = 1, ctrl = 2, alt = 3, shift = 4 }
local function canonical(chord)
  local mods, base = {}, nil
  for part in chord:gmatch("[^+]+") do
    if MOD_ORDER[part] then
      mods[#mods + 1] = part
    else
      base = base and (base .. "+" .. part) or part
    end
  end
  if not base or #mods == 0 then
    return chord
  end
  table.sort(mods, function(a, b)
    return MOD_ORDER[a] < MOD_ORDER[b]
  end)
  mods[#mods + 1] = base
  return table.concat(mods, "+")
end

local seen, chords = {}, {}
local function emit(chord, where)
  if not chord or chord == "" then
    return
  end
  chord = canonical(chord:lower())
  local key = chord .. "\0" .. where
  if not seen[key] then
    seen[key] = true
    chords[#chords + 1] = chord .. "\t" .. where
  end
end

local MODMAP = { SUPER = "cmd", CMD = "cmd", CTRL = "ctrl", SHIFT = "shift", ALT = "alt", OPT = "alt" }
local function normalise_wez(mods, key)
  local parts = {}
  for mod in tostring(mods):gmatch("[^|]+") do
    local m = MODMAP[mod:upper():gsub("%s", "")]
    if m then
      parts[#parts + 1] = m
    end
  end
  parts[#parts + 1] = tostring(key):lower()
  return table.concat(parts, "+")
end

if layer == "wezterm" then
  for _, path in ipairs(files(root, "lua")) do
    local body = uncomment(read(path) or "")
    if body then
      for key, mods in body:gmatch('key%s*=%s*"([^"]+)"%s*,%s*mods%s*=%s*"([^"]*)"') do
        emit(normalise_wez(mods, key), path)
      end
      for mods, key in body:gmatch('mods%s*=%s*"([^"]*)"%s*,%s*key%s*=%s*"([^"]+)"') do
        emit(normalise_wez(mods, key), path)
      end
    end
  end
elseif layer == "neovim" then
  for _, path in ipairs(files(root, "lua")) do
    local body = uncomment(read(path) or "")
    if body then
      for chord in body:gmatch('"(<[Ll]eader>[%w%p]-)"') do
        emit(chord, path)
      end
      for chord in body:gmatch('"(<[CMDcmd]%-[%w%p]-)"') do
        emit(chord, path)
      end
    end
  end
elseif layer == "pi" then
  for _, ext in ipairs({ "ts", "json", "nix" }) do
    for _, path in ipairs(files(root, ext)) do
      local body = read(path)
      if body then
        for chord in body:gmatch('registerShortcut%(%s*"([^"]+)"') do
          emit(chord, path)
        end
        for chord in body:gmatch('"(%a[%w]*%+[%w%+]+)"') do
          if chord:match("ctrl") or chord:match("alt") or chord:match("cmd") or chord:match("shift") then
            emit(chord, path)
          end
        end
      end
    end
  end
else
  io.stderr:write("unknown layer: " .. layer .. "\n")
  os.exit(2)
end

table.sort(chords)
for _, line in ipairs(chords) do
  print(line)
end
