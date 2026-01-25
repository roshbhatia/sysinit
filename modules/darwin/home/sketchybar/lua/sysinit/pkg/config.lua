local config_path = os.getenv("HOME") .. "/.config/sketchybar/config.json"
local file = io.open(config_path, "r")
local content = file:read("*all")
file:close()

local cjson = require("cjson")
return cjson.decode(content)
