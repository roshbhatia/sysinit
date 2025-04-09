-- Keybinding Design Document
-- This file outlines the keybinding structure but doesn't actually set keybindings

--[[
DESIGN PHILOSOPHY:
- Mimic VSCode where beneficial, while leveraging Neovim strengths
- Maintain spacebar as leader key for discoverability
- Use Which-key to organize keybindings logically
- Prefer mnemonic key choices (f for find, g for git, etc.)
- Ensure consistency with common Vim patterns where appropriate
]]--

-- Main Categories for Leader Keybindings
local leader_categories = {
  -- Finding and Navigation
  f = {
    name = "󰈔 Find",
    -- Basic finding
    f = "Find Files",               -- Telescope find_files
    g = "Live Grep",                -- Telescope live_grep
    b = "Find Buffers",             -- Telescope buffers
    s = "Find Symbols",             -- Telescope lsp_document_symbols
    r = "Recent Files",             -- Telescope oldfiles
    p = "Find in Project",          -- Project-wide search
    w = "Find Word",                -- Search for word under cursor
    -- Advanced finding
    t = "Find TODOs",               -- Search for TODOs with telescope
    c = "Find Commands",            -- Telescope commands
    h = "Find Help",                -- Telescope help_tags
    d = "Find Diagnostics",         -- Telescope diagnostics
  },
  
  -- Git operations
  g = {
    name = " Git",
    b = "Git Blame",                -- Git blame (inline)
    s = "Git Status",               -- Open Git status
    d = "Git Diff",                 -- Show Git diff
    c = "Git Commit",               -- Create Git commit
    p = "Git Push",                 -- Push to remote
    l = "Git Pull",                 -- Pull from remote
    h = "Git History",              -- Show file history
    o = "Open Remote",              -- Open in GitHub/GitLab
    m = "Merge Conflict",           -- Navigate merge conflicts
  },
  
  -- Code Intelligence and Refactoring
  c = {
    name = "󰌵 Code",
    a = "Code Actions",             -- Show code actions
    r = "Rename Symbol",            -- Rename symbol
    f = "Format Document",          -- Format current document
    d = "Go to Definition",         -- Go to definition
    i = "Go to Implementation",     -- Go to implementation
    h = "Show Hover",               -- Show hover information
    s = "Symbol Search",            -- Search symbols
    x = "Quick Fix",                -- Quick fix suggestions
    g = "Generate...",              -- Code generation submenu
    l = "LSP Info",                 -- Show LSP information
  },
  
  -- Debugging
  d = {
    name = " Debug",
    b = "Toggle Breakpoint",        -- Set/unset breakpoint
    c = "Continue/Start",           -- Start/continue debugging
    i = "Step Into",                -- Step into
    o = "Step Over",                -- Step over
    O = "Step Out",                 -- Step out
    r = "Run to Cursor",            -- Run to cursor
    e = "Evaluate",                 -- Evaluate expression
    w = "Watch",                    -- Add watch expression
    v = "Variables",                -- Show variables
    u = "UI Toggle",                -- Toggle debug UI
  },
  
  -- Toggle Features
  t = {
    name = "󰙅 Toggle",
    e = "Explorer",                 -- Toggle file explorer
    t = "Terminal",                 -- Toggle terminal
    p = "Problems",                 -- Toggle diagnostics panel
    o = "Outline",                  -- Toggle outline
    c = "Copilot Chat",             -- Toggle Copilot Chat
    b = "Return to Editor",         -- Focus editor
    m = "Command Palette",          -- Show command palette
    h = "Highlight",                -- Toggle search highlighting
    w = "Wrap",                     -- Toggle line wrapping
    n = "Line Numbers",             -- Toggle line numbers
  },
  
  -- Buffer management
  b = {
    name = "󰓩 Buffer",
    n = "Next Buffer",              -- Go to next buffer
    p = "Previous Buffer",          -- Go to previous buffer
    d = "Close Buffer",             -- Close current buffer
    o = "Close Others",             -- Close other buffers
    s = "Save Buffer",              -- Save current buffer
    a = "Save All",                 -- Save all buffers
    f = "Format Buffer",            -- Format current buffer
    r = "Reload Buffer",            -- Reload current buffer
    l = "List Buffers",             -- List all buffers
    c = "Copy Buffer Path",         -- Copy buffer path
  },
  
  -- Window management
  w = {
    name = "󰖮 Window",
    h = "Focus Left",               -- Focus left window
    j = "Focus Down",               -- Focus down window
    k = "Focus Up",                 -- Focus up window
    l = "Focus Right",              -- Focus right window
    v = "Split Vertical",           -- Split window vertically
    s = "Split Horizontal",         -- Split window horizontally
    c = "Close Window",             -- Close current window
    o = "Close Others",             -- Close other windows
    w = "Switch Window",            -- Switch between windows
    m = "Maximize Window",          -- Maximize current window
    r = "Rotate Windows",           -- Rotate windows
    ["="] = "Equal Width",          -- Make windows equal width
  },
  
  -- Harpoon for quick navigation
  h = {
    name = "⚓ Harpoon",
    a = "Add File",                 -- Add file to Harpoon
    h = "Quick Menu",               -- Toggle quick menu
    ["1"] = "File 1",               -- Navigate to file 1
    ["2"] = "File 2",               -- Navigate to file 2
    ["3"] = "File 3",               -- Navigate to file 3
    ["4"] = "File 4",               -- Navigate to file 4
    n = "Next File",                -- Navigate to next file
    p = "Previous File",            -- Navigate to previous file
    c = "Clear All",                -- Clear all marked files
  },
  
  -- Markdown and documentation
  m = {
    name = "󰍔 Markdown",
    p = "Preview",                  -- Toggle markdown preview
    s = "Sync Preview",             -- Sync preview with cursor
    m = "Mermaid Preview",          -- Preview mermaid diagram
    t = "Table Mode",               -- Toggle table mode
    f = "Format Table",             -- Format markdown table
    h = "Heading Up",               -- Navigate to prev heading
    l = "Heading Down",             -- Navigate to next heading
    c = "Create TOC",               -- Generate table of contents
    o = "Open Link",                -- Open link under cursor
  },
  
  -- Refactoring operations
  r = {
    name = "󰑕 Refactor",
    e = "Extract Function",         -- Extract function
    f = "Extract Function To File", -- Extract to new file
    v = "Extract Variable",         -- Extract variable
    i = "Inline Variable",          -- Inline variable
    b = "Extract Block",            -- Extract block
    t = "Extract Type",             -- Extract type (TS/JS)
    p = "Extract Interface",        -- Extract interface/protocol
    r = "Rename",                   -- Rename (alias to cr)
  },
  
  -- Session management
  s = {
    name = "󰑓 Session",
    s = "Save Session",             -- Save session
    l = "Load Session",             -- Load session
    d = "Delete Session",           -- Delete session
    f = "Find Session",             -- Find session
    c = "Close Session",            -- Close current session
    r = "Restart Session",          -- Restart current session
    n = "New Session",              -- Start new session
  },
  
  -- YAML operations
  y = {
    name = "󰒋 YAML",
    s = "Show Schema",              -- Show YAML schema
    a = "Apply Schema",             -- Apply YAML schema
    v = "Validate YAML",            -- Validate YAML document
    o = "Open Schema Browser",      -- Open schema browser
    d = "Show Schema Diagnostics",  -- Show schema diagnostics
  },
  
  -- Project management
  p = {
    name = "󰏗 Project",
    f = "Find File",                -- Find file in project
    g = "Grep in Project",          -- Grep in project
    b = "Browse Project",           -- Browse project structure
    r = "Recent Projects",          -- Show recent projects
    d = "Project Diagnostics",      -- Project-wide diagnostics
    t = "Project Tasks",            -- Show project tasks
    s = "Project Settings",         -- Project settings
    n = "New File",                 -- Create new file
    o = "Open Project",             -- Open another project
  },
  
  -- Terminal and external operations
  x = {
    name = "󰆍 Terminal",
    t = "Toggle Terminal",          -- Toggle terminal
    f = "Float Terminal",           -- Open float terminal
    h = "Horizontal Terminal",      -- Open horizontal terminal
    v = "Vertical Terminal",        -- Open vertical terminal
    r = "Run Command",              -- Run shell command
    g = "Lazygit",                  -- Open Lazygit
    d = "Lazydocker",               -- Open Lazydocker
    n = "Node REPL",                -- Open Node REPL
    p = "Python REPL",              -- Open Python REPL
  },
}

-- Non-leader keybindings (mostly defaults plus some enhancements)
local non_leader_bindings = {
  normal_mode = {
    -- Window navigation
    ["<C-h>"] = "Move to left window",
    ["<C-j>"] = "Move to bottom window",
    ["<C-k>"] = "Move to top window",
    ["<C-l>"] = "Move to right window",
    
    -- Better window resizing
    ["<C-Up>"] = "Increase window height",
    ["<C-Down>"] = "Decrease window height",
    ["<C-Left>"] = "Decrease window width",
    ["<C-Right>"] = "Increase window width",
    
    -- Better navigation
    ["<C-d>"] = "Page down and center",
    ["<C-u>"] = "Page up and center",
    ["n"] = "Next search result and center",
    ["N"] = "Previous search result and center",
    
    -- Buffer navigation
    ["H"] = "Previous buffer",
    ["L"] = "Next buffer",
    
    -- Quick save
    ["<C-s>"] = "Save file",
    
    -- Quick comment
    ["gcc"] = "Comment line",
    
    -- UI toggles
    ["<F2>"] = "Toggle file explorer",
    ["<F3>"] = "Toggle outline",
    ["<F4>"] = "Toggle terminal",
    ["<F5>"] = "Start/continue debug",
    
    -- Copilot
    ["<M-]>"] = "Next Copilot suggestion",
    ["<M-[>"] = "Previous Copilot suggestion",
    ["<M-\\>"] = "Accept Copilot suggestion",
  },
  
  insert_mode = {
    -- Copilot
    ["<M-]>"] = "Next Copilot suggestion",
    ["<M-[>"] = "Previous Copilot suggestion",
    ["<M-\\>"] = "Accept Copilot suggestion",
    
    -- Quick escape
    ["jk"] = "Escape insert mode",
    ["kj"] = "Escape insert mode",
    
    -- Quick save
    ["<C-s>"] = "Save file",
  },
  
  visual_mode = {
    -- Stay in visual mode when indenting
    ["<"] = "Indent left and keep selection",
    [">"] = "Indent right and keep selection",
    
    -- Move lines in visual mode
    ["J"] = "Move selection down",
    ["K"] = "Move selection up",
    
    -- Comment in visual mode
    ["gc"] = "Comment selection",
    
    -- Search for visually selected text
    ["*"] = "Search for selection forward",
    ["#"] = "Search for selection backward",
  },
  
  command_mode = {
    -- Bash-like shortcuts in command mode
    ["<C-a>"] = "Beginning of line",
    ["<C-e>"] = "End of line",
    ["<C-b>"] = "Back one character",
    ["<C-f>"] = "Forward one character",
  },
}

-- Special keybindings for specific plugins
local plugin_specific = {
  -- CHADTree
  ["chadtree"] = {
    ["<leader>e"] = "Toggle CHADTree",
    ["<F2>"] = "Toggle CHADTree",
  },
  
  -- Telescope
  ["telescope"] = {
    ["<C-p>"] = "Find files",
    ["<leader>ff"] = "Find files",
    ["<leader>fg"] = "Live grep",
  },
  
  -- DAP
  ["dap"] = {
    ["<F5>"] = "Start/Continue",
    ["<F10>"] = "Step over",
    ["<F11>"] = "Step into",
    ["<F12>"] = "Step out",
  },
  
  -- Harpoon
  ["harpoon"] = {
    ["<leader>ha"] = "Add file",
    ["<leader>hh"] = "Quick menu",
  },
  
  -- Copilot
  ["copilot"] = {
    ["<leader>cc"] = "Toggle Copilot Chat",
    ["<M-\\>"] = "Accept suggestion",
  },
  
  -- Markdown preview
  ["markdown"] = {
    ["<leader>mp"] = "Toggle preview",
  },
}

-- Return the design (only for documentation purposes)
return {
  leader_categories = leader_categories,
  non_leader_bindings = non_leader_bindings,
  plugin_specific = plugin_specific
}