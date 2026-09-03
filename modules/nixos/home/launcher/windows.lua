Name = "windows"
NamePretty = "Windows"
Icon = "preferences-system-windows"
Action = "lua:Focus"
SearchName = true
History = true

-- @menu-prelude@

local function socket()
  local held = os.getenv("SWAYSOCK")
  if held ~= nil and held ~= "" then
    return held
  end
  local runtime = os.getenv("XDG_RUNTIME_DIR") or ("/run/user/" .. (os.getenv("UID") or "1000"))
  local handle = io.popen("@ls@ -t " .. runtime .. "/sway-ipc.*.sock 2>/dev/null | @head@ -1")
  if handle == nil then
    return nil
  end
  local found = handle:read("*line")
  handle:close()
  return found
end

function GetEntries()
  local entries = {}
  local sock = socket()
  if sock == nil or sock == "" then
    return entries
  end
  local cmd = [[@swaymsg@ --socket ]]
    .. sock
    .. [[ -t get_tree | @jq@ -r '
    [
      recurse(.nodes[]?, .floating_nodes[]?)
      | select(.type == "con" or .type == "floating_con")
      | select(.name != null)
    ]
    | .[]
    | [.id, .name, (.app_id // .window_properties.class // "")]
    | @tsv
  ']]
  for _, row in ipairs(lines(cmd)) do
    if row[1] ~= nil and row[1] ~= "" then
      entries[#entries + 1] = {
        Text = row[2] or "",
        Subtext = row[3] or "",
        Value = row[1],
      }
    end
  end
  return entries
end

function Focus(value)
  local sock = socket()
  if sock == nil or sock == "" then
    return
  end
  os.execute("@swaymsg@ --socket " .. sock .. " '[con_id=" .. value .. "] focus'")
end
