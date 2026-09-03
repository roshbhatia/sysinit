local function fields(line)
  local out = {}
  for part in string.gmatch(line .. "\t", "([^\t]*)\t") do
    out[#out + 1] = part
  end
  return out
end

local function lines(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if handle == nil then
    return {}
  end
  local out = handle:read("*all")
  handle:close()
  local rows = {}
  for line in string.gmatch(out or "", "[^\n]+") do
    rows[#rows + 1] = fields(line)
  end
  return rows
end
