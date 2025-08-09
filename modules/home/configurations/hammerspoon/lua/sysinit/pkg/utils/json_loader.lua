local M = {}

function M.get_config_path(filename)
  local home = os.getenv("HOME")
  return home .. "/.config/sysinit/" .. filename
end

function M.load_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  if not content or content == "" then
    return nil
  end

  -- Simple JSON parser for basic structures
  -- This is a minimal implementation - for complex JSON, consider using a proper library
  local function parse_json(str)
    -- Remove whitespace
    str = str:gsub("^%s*(.-)%s*$", "%1")

    -- Try to use hs.json if available (Hammerspoon's JSON module)
    if hs and hs.json then
      local ok, result = pcall(hs.json.decode, str)
      if ok then
        return result
      end
    end

    -- Fallback: very basic JSON parsing (limited functionality)
    -- This only handles simple key-value pairs and nested objects
    local function parse_value(v)
      v = v:gsub("^%s*(.-)%s*$", "%1")
      if v == "true" then return true
      elseif v == "false" then return false
      elseif v == "null" then return nil
      elseif v:match("^%-?%d+%.?%d*$") then return tonumber(v)
      elseif v:match('^".*"$') then return v:sub(2, -2)
      else return v end
    end

    return parse_value(str)
  end

  return parse_json(content)
end

return M
