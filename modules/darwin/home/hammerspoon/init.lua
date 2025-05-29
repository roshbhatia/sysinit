local hyperKey = { "cmd", "ctrl" }

hs.hotkey.bind(hyperKey, "h", function()
	hs.window.focusWindowWest()
end)
hs.hotkey.bind(hyperKey, "j", function()
	hs.window.focusWindowSouth()
end)
hs.hotkey.bind(hyperKey, "k", function()
	hs.window.focusWindowNorth()
end)
hs.hotkey.bind(hyperKey, "l", function()
	hs.window.focusWindowEast()
end)
