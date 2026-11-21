local function extend_process_set(base, names)
  local result = {}
  for name in pairs(base) do
    result[name] = true
  end
  for _, name in ipairs(names) do
    result[name] = true
  end
  return result
end

local editors = { nvim = true, vim = true, hx = true }
local navigation_passthrough = extend_process_set(editors, { "traces", "orc" })
local scroll_passthrough = extend_process_set(
  navigation_passthrough,
  { "slk", "diffnav", "changes", "zsh", "bash", "fish", "sh", "nu" }
)

rex.action({
  name = "sysinit_guarded_key",
  title = "Run terminal shortcut",
  repeats = true,
  args = { key = "string", action = "string", passthrough = "object", arguments = "object?" },
  run = function(_, args)
    local process = rex.block.call("com.superlogical.terminal", "process", {})
    local foreground = process and process.foreground
    if not foreground or args.passthrough[foreground.name] then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue(args.action, args.arguments)
    end
  end,
})

local function bind_guarded(key, action, passthrough, arguments)
  rex.bind(key, "sysinit_guarded_key", {
    key = key,
    action = action,
    passthrough = passthrough,
    arguments = arguments,
  })
end

rex.action({
  name = "sysinit_close_pane",
  title = "Close or detach",
  args = { close_only = "boolean?" },
  run = function(_, args)
    local choices = { { id = "pane.close", title = "Close pane and end its process" } }
    if not args.close_only then
      choices[#choices + 1] = {
        id = "client.window.close",
        title = "Close the window and keep the session running",
      }
    end

    local choice = rex.ui.pick({ title = "Close or detach?", items = choices })
    if choice then
      rex.client.queue(choice)
    end
  end,
})

local bindings = {
  ["cmd+s"] = "session.switch",
  ["ctrl+cmd+p"] = "pane.go_to",
  ["ctrl+shift+f"] = "pane.go_to",
  ["ctrl+s"] = "pane.split.down",
  ["ctrl+v"] = "pane.split.right",
  ["ctrl+shift+s"] = "pane.split.down",
  ["ctrl+shift+v"] = "pane.split.right",
  ["cmd+shift+v"] = "pane.split.right",
  ["ctrl+m"] = "pane.zoom",
  ["cmd+f"] = "pane.float",
  ["ctrl+w"] = "sysinit_close_pane",
  ["cmd+w"] = "sysinit_close_pane",
  ["ctrl+t"] = "client.tab.new",
  ["cmd+t"] = "client.tab.new",
  ["ctrl+shift+t"] = "client.tab.new",
  ["cmd+shift+t"] = "client.tab.new",
  ["ctrl+tab"] = "client.tab.next",
  ["ctrl+shift+tab"] = "client.tab.previous",
  ["ctrl+shift+o"] = "client.tab.recent.in_session",
  ["ctrl+shift+r"] = "client.tab.rename",
  ["cmd+shift+r"] = "client.tab.rename",
  ["ctrl+shift+,"] = "client.tab.move.backward",
  ["ctrl+shift+."] = "client.tab.move.forward",
  ["cmd+n"] = "client.window.new",
  ["cmd+shift+n"] = "client.window.new",
  ["ctrl+cmd+f"] = "client.window.fullscreen.toggle",
  ["cmd+r"] = "client.config.reload",
  ["cmd+;"] = "client.palette.toggle",
  ["cmd+shift+;"] = "client.palette.toggle",
  ["ctrl+;"] = "client.palette.toggle",
  ["ctrl+shift+p"] = "client.palette.toggle",
  ["cmd+shift+p"] = "client.palette.toggle",
  ["cmd+c"] = "pane.copy",
  ["ctrl+shift+c"] = "pane.copy",
  ["cmd+v"] = "pane.paste",
  ["cmd+/"] = "client.find.open",
  ["ctrl+escape"] = "pane.copy_mode.enter",
  ["ctrl+shift+x"] = "pane.copy_mode.enter",
}

for key, action in pairs(bindings) do
  rex.bind(key, action)
end

rex.bind("ctrl+shift+w", "sysinit_close_pane", { close_only = true })
rex.bind("cmd+shift+w", "sysinit_close_pane", { close_only = true })
rex.bind("cmd+k", "pane.send_key", { key = "ctrl+l" })

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  bind_guarded("ctrl+" .. key, "pane.focus." .. direction, navigation_passthrough)
  bind_guarded("ctrl+shift+" .. key, "pane.resize", editors, { direction = direction, amount = 3 })
  rex.bind("ctrl+cmd+" .. direction, "pane.resize", { direction = direction, amount = 3 })
end

for _, modifier in ipairs({ "ctrl+", "cmd+" }) do
  rex.bind(modifier .. "-", "client.font.decrease")
  rex.bind(modifier .. "=", "client.font.increase")
  rex.bind(modifier .. "[Digit0]", "client.font.reset")
  for digit = 1, 9 do
    rex.bind(
      modifier .. "[Digit" .. digit .. "]",
      "client.tab.goto",
      { index = digit == 9 and -1 or digit }
    )
  end
end

bind_guarded("ctrl+/", "client.find.open", editors)
bind_guarded("ctrl+shift+up", "client.prompt.previous", editors)
bind_guarded("ctrl+shift+down", "client.prompt.next", editors)
bind_guarded("ctrl+u", "client.scroll.page_up", scroll_passthrough)
bind_guarded("ctrl+d", "client.scroll.page_down", scroll_passthrough)
rex.bind("cmd+u", "client.scroll.page_up")
rex.bind("cmd+d", "client.scroll.page_down")
