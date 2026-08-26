local lua_root = assert(os.getenv("SYSINIT_WEZTERM_LUA"), "SYSINIT_WEZTERM_LUA is required")

package.path = table.concat({
  lua_root .. "/?.lua",
  lua_root .. "/?/init.lua",
  package.path,
}, ";")

return require("sysinit.pkg.bootstrap").build()
