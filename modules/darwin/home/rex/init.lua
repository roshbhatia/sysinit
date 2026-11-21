local directions = { h = "left", j = "down", k = "up", l = "right" }

rex.mode("panes", { exclusive = true })
rex.bind("ctrl+cmd+p", "client.mode.enter", { name = "panes" })

for key, direction in pairs(directions) do
  rex.bind("panes/" .. key, "pane.focus." .. direction)
  rex.bind("panes/shift+" .. key, "pane.resize", { direction = direction, amount = 3 })
end

rex.bind("panes/s", "pane.split.down")
rex.bind("panes/v", "pane.split.right")
rex.bind("panes/m", "pane.zoom")
