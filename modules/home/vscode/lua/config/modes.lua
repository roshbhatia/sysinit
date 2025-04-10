-- Enhanced mode display configuration with more vibrant colors
local M = {}

M.MODE_DISPLAY = {
    n = { text = 'NORMAL', color = '#7aa2f7' },      -- Vibrant blue
    i = { text = 'INSERT', color = '#9ece6a' },      -- Soft green
    v = { text = 'VISUAL', color = '#bb9af7' },      -- Rich purple
    V = { text = 'V-LINE', color = '#bb9af7' },      -- Matching visual mode
    ['\22'] = { text = 'V-BLOCK', color = '#bb9af7' },
    R = { text = 'REPLACE', color = '#f7768e' },     -- Strong pink
    s = { text = 'SELECT', color = '#ff9e64' },      -- Warm orange
    S = { text = 'S-LINE', color = '#ff9e64' },      
    ['\19'] = { text = 'S-BLOCK', color = '#ff9e64' },
    c = { text = 'COMMAND', color = '#7dcfff' },     -- Bright cyan
    t = { text = 'TERMINAL', color = '#73daca' }     -- Mint green
}

return M
