local config_path = os.getenv("HOME") .. "/.config/sketchybar/config.json"
local file = assert(io.open(config_path, "r"))
local content = assert(file:read("*all"))
assert(file:close())

local cjson = require("cjson")
return cjson.decode(content)
