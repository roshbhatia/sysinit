local router, review_uri, root, file_uri, turn = table.unpack(arg)
local handler, palette, routed, notice, default_path
local domain = "unix"
local fullscreen = false

package.loaded.wezterm = {
  action = { OpenLinkAtMouseCursor = "open", Nop = "nop" },
  action_callback = function(callback)
    return callback
  end,
  on = function(event, callback)
    if event == "open-uri" then
      handler = callback
    else
      assert(event == "augment-command-palette")
      palette = callback
    end
  end,
  hostname = function()
    return "host"
  end,
  log_error = function() end,
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
    if args[3] == "/profile/bin/agent-review-link" then
      assert(args[4] == "--resolve")
      if args[5] == review_uri then
        return true, root .. "\n", ""
      end
      return false, "", "Invalid review link"
    end
    routed = args
    return true, "", ""
  end,
  open_with = function(path)
    default_path = path
  end,
}

local window = {
  get_dimensions = function()
    return { is_full_screen = fullscreen }
  end,
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

local links = dofile(router)
local function click(event, mouse_reporting, action)
  return {
    event = { [event] = { streak = 1, button = "Left" } },
    mods = "SUPER",
    mouse_reporting = mouse_reporting,
    action = action,
  }
end

local captured_down = click("Down", true, "nop")
local captured_up = click("Up", true, "open")
local normal_up = click("Up", false, "open")
links.configure_mouse({ mouse_bindings = { captured_down, captured_up, normal_up } })
assert(captured_down.action == "open")
assert(captured_up.action == "nop")
assert(normal_up.action == "open")

local review = links.setup({
  bin = "/profile/bin",
  home = "/home/test",
  file = "/bin/file",
  path = "/profile/bin",
})
assert(handler(window, pane, review_uri) == false)
assert(routed[3] == "/profile/bin/agent-diff")
assert(routed[4] == "--pane-id=42")
assert(routed[5] == "--cwd=" .. root)
assert(routed[6] == (turn and "--turn=" .. turn or nil))
fullscreen = true
assert(handler(window, pane, review_uri) == false)
assert(routed[#routed] == "--fullscreen")

local config = links.build_config(function()
  require("wezterm").on("augment-command-palette", function()
    return { { brief = "Existing action" } }
  end)
  return { hyperlink_rules = {} }
end, review)
links.configure_hyperlinks(config)
assert(config.hyperlink_rules[1].format == "$1")
local entries = palette(window, pane)
assert(#entries == 2 and entries[1].brief == "Existing action")
assert(entries[2].brief == "Open Worktree Review")
routed = nil
entries[2].action(window, pane)
local palette_route = assert(routed)
assert(palette_route[3] == "/profile/bin/agent-diff")
assert(palette_route[4] == "--pane-id=42")
assert(palette_route[5] == "--cwd=" .. root)
assert(palette_route[6] == "--fullscreen")
fullscreen = false

routed = nil
assert(handler(window, pane, "review://worktree/0000000000000000") == false)
assert(handler(window, pane, "review://other/path") == nil)
assert(routed == nil)
domain = "remote"
assert(handler(window, pane, review_uri) == false)
assert(routed == nil and notice:find("remote shell", 1, true))
domain = "unix"

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
