vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Normal mode keymaps
----------------------

-- Better window navigation with smart-splits
map("n", "<C-h>", ":lua require('smart-splits').move_cursor_left()<CR>", { desc = "Navigate left window" })
map("n", "<C-j>", ":lua require('smart-splits').move_cursor_down()<CR>", { desc = "Navigate down window" })
map("n", "<C-k>", ":lua require('smart-splits').move_cursor_up()<CR>", { desc = "Navigate up window" })
map("n", "<C-l>", ":lua require('smart-splits').move_cursor_right()<CR>", { desc = "Navigate right window" })

-- Window management
map("n", "<leader>wv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>ws", ":split<CR>", { desc = "Split window horizontally" })
map("n", "<leader>wc", ":close<CR>", { desc = "Close window" })
map("n", "<leader>wo", ":only<CR>", { desc = "Close other windows" })
map("n", "<leader>ww", "<C-w>w", { desc = "Switch between windows" })
map("n", "<leader>w=", "<C-w>=", { desc = "Make windows equal width" })
map("n", "<leader>wm", ":MaximizerToggle<CR>", { desc = "Maximize/restore window" })
map("n", "<leader>wr", ":lua require('smart-splits').start_resize_mode()<CR>", { desc = "Start resize mode" })
map("n", "<leader>wS", ":lua require('smart-splits').swap_buf_in_direction()<CR>", { desc = "Swap buffers in direction" })

-- Better window resizing with smart-splits
map("n", "<C-Up>", ":lua require('smart-splits').resize_up()<CR>", { desc = "Decrease window height" })
map("n", "<C-Down>", ":lua require('smart-splits').resize_down()<CR>", { desc = "Increase window height" })
map("n", "<C-Left>", ":lua require('smart-splits').resize_left()<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", ":lua require('smart-splits').resize_right()<CR>", { desc = "Increase window width" })

-- Navigate buffers
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":Bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>bc", ":Bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>bo", ":BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
map("n", "<leader>ba", ":bufdo bd<CR>", { desc = "Close all buffers" })

-- Improved navigation
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "J", "mzJ`z", { desc = "Join lines and maintain cursor position" })

-- Quick Save / Quit
map("n", "<C-s>", ":w<CR>", { desc = "Save file" })
map("n", "<leader>bs", ":w<CR>", { desc = "Save file" })
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Force quit all" })
map("n", "<leader>ba", ":wa<CR>", { desc = "Save all buffers" })

-- Select All / Copy / Cut / Paste
map("n", "<D-a>", "ggVG", { desc = "Select all text" })
map("v", "<D-a>", "<Esc>ggVG", { desc = "Select all text" })
map("i", "<D-a>", "<Esc>ggVG", { desc = "Select all text" })

-- macOS-like copy/cut/paste (with Cmd key)
map("n", "<D-c>", "\"+y", { desc = "Copy to system clipboard" })
map("v", "<D-c>", "\"+y", { desc = "Copy to system clipboard" })
map("n", "<D-x>", "\"+d", { desc = "Cut to system clipboard" })
map("v", "<D-x>", "\"+d", { desc = "Cut to system clipboard" })
map("n", "<D-p>", "\"+p", { desc = "Paste from system clipboard" })
map("v", "<D-p>", "\"+p", { desc = "Paste from system clipboard" })
map("i", "<D-p>", "<C-r>+", { desc = "Paste from system clipboard" })

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Find help" })
map("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fc", ":Telescope commands<CR>", { desc = "Find commands" })
map("n", "<leader>ft", ":TodoTelescope<CR>", { desc = "Find todos" })
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", { desc = "Find document symbols" })
map("n", "<leader>fw", ":Telescope grep_string<CR>", { desc = "Find word under cursor" })
map("n", "<leader>fd", ":Telescope diagnostics<CR>", { desc = "Find diagnostics" })
map("n", "<C-p>", ":Telescope find_files<CR>", { desc = "Find files" })

-- File Explorer
map("n", "<leader>e", ":CHADopen<CR>", { desc = "Open file explorer" })
map("n", "<F2>", ":CHADopen<CR>", { desc = "Open file explorer" })

-- Code navigation
map("n", "gd", ":lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
map("n", "gr", ":lua vim.lsp.buf.references()<CR>", { desc = "Show references" })
map("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", { desc = "Go to implementation" })
map("n", "K", ":lua vim.lsp.buf.hover()<CR>", { desc = "Show hover information" })
map("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>", { desc = "Show code actions" })
map("n", "<leader>cr", ":lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
map("n", "<leader>cf", ":lua vim.lsp.buf.format({ async = true })<CR>", { desc = "Format document" })
map("n", "<leader>cl", ":lua vim.diagnostic.open_float()<CR>", { desc = "Line diagnostics" })
map("n", "[d", ":lua vim.diagnostic.goto_prev()<CR>", { desc = "Previous diagnostic" })
map("n", "]d", ":lua vim.diagnostic.goto_next()<CR>", { desc = "Next diagnostic" })

-- Go back and forward in jump list
map("n", "<C-b>", "<C-o>", { desc = "Go back in jump list" })
map("n", "<C-f>", "<C-i>", { desc = "Go forward in jump list" })

-- Toggle terminal removed

-- Git operations
map("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
map("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview git hunk" })
map("n", "<leader>gb", ":Gitsigns blame_line<CR>", { desc = "Git blame line" })
map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
map("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
map("n", "<leader>gR", ":Gitsigns reset_buffer<CR>", { desc = "Reset buffer" })
map("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "Undo stage hunk" })
map("n", "<leader>gd", ":Gitsigns diffthis<CR>", { desc = "Diff this" })
map("n", "]g", ":Gitsigns next_hunk<CR>", { desc = "Next git hunk" })
map("n", "[g", ":Gitsigns prev_hunk<CR>", { desc = "Previous git hunk" })

-- UI Toggles
map("n", "<leader>to", ":SymbolsOutline<CR>", { desc = "Toggle outline" })
map("n", "<leader>tc", ":ColorizerToggle<CR>", { desc = "Toggle color highlight" })
map("n", "<leader>tn", ":set number!<CR>", { desc = "Toggle line numbers" })
map("n", "<leader>tr", ":set relativenumber!<CR>", { desc = "Toggle relative numbers" })
map("n", "<leader>th", ":set hlsearch!<CR>", { desc = "Toggle search highlight" })
map("n", "<leader>tw", ":set wrap!<CR>", { desc = "Toggle word wrap" })
map("n", "<leader>ts", ":set spell!<CR>", { desc = "Toggle spell check" })

-- Harpoon
map("n", "<leader>ha", ":lua require('harpoon'):list():append()<CR>", { desc = "Add file to harpoon" })
map("n", "<leader>hh", ":lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>", { desc = "Harpoon menu" })
map("n", "<leader>h1", ":lua require('harpoon'):list():select(1)<CR>", { desc = "Harpoon file 1" })
map("n", "<leader>h2", ":lua require('harpoon'):list():select(2)<CR>", { desc = "Harpoon file 2" })
map("n", "<leader>h3", ":lua require('harpoon'):list():select(3)<CR>", { desc = "Harpoon file 3" })
map("n", "<leader>h4", ":lua require('harpoon'):list():select(4)<CR>", { desc = "Harpoon file 4" })
map("n", "<leader>hn", ":lua require('harpoon'):list():next()<CR>", { desc = "Next harpoon file" })
map("n", "<leader>hp", ":lua require('harpoon'):list():prev()<CR>", { desc = "Previous harpoon file" })

-- Copilot
map("n", "<leader>cc", ":CopilotChat<CR>", { desc = "Copilot Chat" })
map("n", "<leader>ce", ":CopilotChatExplain<CR>", { desc = "Explain code" })
map("n", "<leader>ct", ":CopilotChatTests<CR>", { desc = "Generate tests" })
map("n", "<leader>cd", ":CopilotChatDocs<CR>", { desc = "Document code" })
map("n", "<leader>cf", ":CopilotChatFix<CR>", { desc = "Fix code" })
map("n", "<leader>co", ":CopilotChatOptimize<CR>", { desc = "Optimize code" })

-- Debugging
map("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>", { desc = "Toggle breakpoint" })
map("n", "<leader>dc", ":lua require'dap'.continue()<CR>", { desc = "Continue/Start debug" })
map("n", "<leader>di", ":lua require'dap'.step_into()<CR>", { desc = "Step into" })
map("n", "<leader>do", ":lua require'dap'.step_over()<CR>", { desc = "Step over" })
map("n", "<leader>dO", ":lua require'dap'.step_out()<CR>", { desc = "Step out" })
map("n", "<leader>dr", ":lua require'dap'.repl.toggle()<CR>", { desc = "Toggle REPL" })
map("n", "<leader>dl", ":lua require'dap'.run_last()<CR>", { desc = "Run last debug config" })
map("n", "<leader>du", ":lua require'dapui'.toggle()<CR>", { desc = "Toggle debug UI" })
map("n", "<leader>dt", ":lua require'dap'.terminate()<CR>", { desc = "Terminate debug session" })

-- Session management
map("n", "<leader>ss", ":lua require('persistence').load()<CR>", { desc = "Load session from current dir" })
map("n", "<leader>sl", ":lua require('persistence').load({ last = true })<CR>", { desc = "Load last session" })
map("n", "<leader>sd", ":lua require('persistence').stop()<CR>", { desc = "Stop saving session" })

-- Testing removed

-- Markdown preview
map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { desc = "Toggle markdown preview" })

-- Refactoring
map("n", "<leader>re", ":Refactor extract ", { desc = "Extract function" })
map("n", "<leader>rf", ":Refactor extract_to_file ", { desc = "Extract to file" })
map("n", "<leader>rv", ":Refactor extract_var ", { desc = "Extract variable" })
map("n", "<leader>ri", ":Refactor inline_var<CR>", { desc = "Inline variable" })
map("n", "<leader>rb", ":Refactor extract_block<CR>", { desc = "Extract block" })
map("n", "<leader>rr", ":Refactor<CR>", { desc = "Refactor menu" })

-- Insert mode keymaps
----------------------

-- Press jk fast to enter Normal mode
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })
map("i", "kj", "<ESC>", { desc = "Exit insert mode" })

-- Quick save in insert mode
map("i", "<C-s>", "<ESC>:w<CR>", { desc = "Save file" })

-- Visual mode keymaps
----------------------

-- Stay in visual mode when indenting
map("v", "<", "<gv", { desc = "Indent left and stay in visual" })
map("v", ">", ">gv", { desc = "Indent right and stay in visual" })

-- Move text up and down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up" })

-- Hold onto yanked text when pasting in visual mode
map("v", "p", '"_dP', { desc = "Paste without yanking selection" })

-- Terminal mode keymaps
-----------------------

-- Escape terminal mode
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "kj", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- NOTE: Additional plugin-specific keymaps are defined in their respective plugin configurations