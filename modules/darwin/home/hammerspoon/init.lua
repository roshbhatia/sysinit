local leader = { "cmd", "ctrl" }

hs.hotkey.bind(leader, "j", function()
	hs.window.focusedWindow():focusWindowSouth(nil, false)
end)
hs.hotkey.bind(leader, "k", function()
	hs.window.focusedWindow():focusWindowNorth(nil, false)
end)
hs.hotkey.bind(leader, "h", function()
	hs.window.focusedWindow():focusWindowWest(nil, false)
end)
hs.hotkey.bind(leader, "l", function()
	hs.window.focusedWindow():focusWindowEast(nil, false)
end)
