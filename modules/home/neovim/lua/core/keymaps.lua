vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- LSP-like functionality
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

-- Quick window operations
map("n", "<C-w>c", ":close<CR>", { desc = "Close window" })
map("n", "<C-w>o", ":only<CR>", { desc = "Close other windows" })
map("n", "<C-w>=", ":wincmd =<CR>", { desc = "Equal window sizes" })

-- Window movement
map("n", "<C-h>", ":wincmd h<CR>", { desc = "Move to left window" })
map("n", "<C-j>", ":wincmd j<CR>", { desc = "Move to bottom window" })
map("n", "<C-k>", ":wincmd k<CR>", { desc = "Move to top window" })
map("n", "<C-l>", ":wincmd l<CR>", { desc = "Move to right window" })

-- Buffer navigation
map("n", "H", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "L", ":bnext<CR>", { desc = "Next buffer" })

-- Quick UI toggles
map("n", "<C-n>", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
map("n", "<C-\\>", ":ToggleTerm<CR>", { desc = "Toggle terminal" })

-- Line manipulation
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Terminal mode escapes
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "kj", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Visual mode improvements
map("v", "<", "<gv", { desc = "Indent left and stay in visual" })
map("v", ">", ">gv", { desc = "Indent right and stay in visual" })
map("v", "p", '"_dP', { desc = "Paste without yanking selection" })

-- Yank improvements
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Quick save/exit
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Quick return to editor
map("n", "<Esc><Esc>", "<C-\\><C-n>:noh<CR>", { desc = "Clear search highlight and return to normal mode" })

-- Quick find command palette
map({ "n", "i" }, "<D-p>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })