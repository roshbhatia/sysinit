package.path = os.getenv("HOME") .. "/.hammerspoon/lua/?.lua;" .. package.path
require("app_switcher").setup()
