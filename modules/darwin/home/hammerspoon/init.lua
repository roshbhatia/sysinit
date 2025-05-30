local leader = { "cmd", "ctrl" }

local directions = {
	{
		key = "j",
		method = "focusWindowSouth",
	},
	{
		key = "k",
		method = "focusWindowNorth",
	},
	{
		key = "h",
		method = "focusWindowWest",
	},
	{
		key = "l",
		method = "focusWindowEast",
	},
}

for _, dir in ipairs(directions) do
	hs.hotkey.bind(leader, dir.key, function()
		hs.window.focusedWindow()[dir.method](hs.window.focusedWindow(), nil, false)
	end)
end
