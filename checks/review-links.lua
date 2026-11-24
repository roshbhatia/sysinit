local router, review_uri, root = table.unpack(arg)
local handler, routed, notice, default_path
local domain = "unix"

package.loaded.wezterm = {
  on = function(event, callback)
    assert(event == "open-uri")
    handler = callback
  end,
  hostname = function()
    return "host"
  end,
  url = {
    parse = function(uri)
      local host, path = uri:match("^file://([^/]*)(/[^#]*)")
      return {
        host = host,
        file_path = path and path:gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end),
        fragment = uri:match("#(.+)$"),
      }
    end,
  },
  run_child_process = function(args)
    if args[1] == "/bin/file" then
      return true, args[#args]:match("%.png$") and "image/png" or "text/plain"
    end
    routed = args
    return true, "", ""
  end,
  open_with = function(path)
    default_path = path
  end,
}

local window = {
  toast_notification = function(_, _, message)
    notice = message
  end,
}
local pane = {
  pane_id = function()
    return 42
  end,
  get_domain_name = function()
    return domain
  end,
  get_current_working_dir = function()
    return { file_path = root }
  end,
}

dofile(router).setup({
  bin = "/profile/bin",
  home = "/home/test",
  file = "/bin/file",
  path = "/profile/bin",
})
assert(handler(window, pane, review_uri) == false)
assert(routed[3] == "/profile/bin/agent-diff")
assert(routed[4] == "--pane-id=42")
assert(routed[5] == "--cwd=" .. root)

routed = nil
assert(handler(window, pane, "review://other/path") == false)
assert(routed == nil)
domain = "remote"
assert(handler(window, pane, review_uri) == false)
assert(routed == nil and notice:find("remote shell", 1, true))
domain = "unix"

local file_uri = "file:" .. review_uri:sub(8)
assert(handler(window, pane, file_uri .. "/file.nu#L10") == false)
local source = assert(routed)
assert(source[3] == "/profile/bin/ty")
assert(source[#source - 3] == "/profile/bin/nvim")
assert(source[#source - 2] == "+call cursor(10,1)")
assert(source[#source] == root .. "/file.nu")
assert(handler(window, pane, "sysinit-file:src/main.nu:2:3") == false)
source = assert(routed)
assert(source[#source - 2] == "+call cursor(2,3)")
assert(source[#source] == root .. "/src/main.nu")
assert(handler(window, pane, file_uri .. "/image.png") == false)
assert(default_path == root .. "/image.png")
assert(handler(window, pane, "https://example.com") == nil)
