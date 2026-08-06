local M = {}

-- Sidebar panels — skip resize, skip as open targets
M.sidebar_filetypes = { "neo-tree", "grug-far", "Outline" }

-- Utility buffers — strip decorations, skip resize
M.utility_filetypes = { "oil", "oil_preview", "quickfix", "help" }
M.utility_buftypes = { "nofile", "quickfix", "prompt" }

return M
