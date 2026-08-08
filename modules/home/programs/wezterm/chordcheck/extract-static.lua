-- Static chord extraction. Reads source text and never loads a module.
--
-- extract.lua loads keybindings.lua under a stub, which works there and cannot
-- work for ui.lua: that file pulls in tabline, lantern, and workspace-manager and
-- dies at module scope. The old check worked around it with a hand-written
-- `uiChords` list of 11 entries against 33 chord literals in the file, kept in
-- step by a comment asking someone to remember. It was already out of step.
--
-- Reading text covers every layer with one mechanism: wezterm lua, neovim lua,
-- and pi TypeScript. It cannot see a chord assembled at runtime from variables,
-- so it is a floor on coverage, not a ceiling. extract.lua stays for
-- keybindings.lua, where loading resolves exactly those computed cases.
--
-- Usage: lua extract-static.lua <layer> <root>
--   layer: wezterm | neovim | pi

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

-- A chord written inside a comment is usually one the code deliberately does NOT
-- bind. Counting it inflated the wezterm floor by two phantom entries.
local function uncomment(body)
  local out = {}
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    if not line:match("^%s*%-%-") then
      out[#out + 1] = line
    end
  end
  return table.concat(out, "\n")
end

-- `find` rather than a Lua directory API: the check runs under a sandbox with
-- coreutils and findutils, and lfs is not in the closure.
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

-- Modifier order is not canonical in source: pi's own files carry both
-- `ctrl+shift+r` and `shift+ctrl+b`. Compared literally, two spellings of one
-- chord never collide and the gate reports nothing. Sorting the modifiers makes
-- the comparison meaningful.
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

-- WezTerm writes mods as SUPER|SHIFT and key separately. Normalise to the same
-- `a+b+key` spelling every other layer uses, so a collision across layers is a
-- string comparison rather than a per-layer special case.
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
      -- Both orderings appear in this codebase, so match each independently
      -- rather than assuming one field comes first.
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
      -- Leader maps are the bulk of the surface and collide with each other far
      -- more often than with a modifier chord.
      for chord in body:gmatch('"(<[Ll]eader>[%w%p]-)"') do
        emit(chord, path)
      end
      -- Modifier chords in vim spelling: <C-x>, <M-x>, <D-x>.
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
        -- keybindings.json is rendered from Nix, so the literal appears in the
        -- .nix source as `"id" = "chord";`.
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
