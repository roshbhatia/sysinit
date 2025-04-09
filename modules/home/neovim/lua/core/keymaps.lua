-- Core key mappings
-- This file contains basic key mappings independent of plugins

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Helper function for mapping
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Easy escape from insert mode
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")

-- Better window navigation (like VSCode)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Resize windows with arrows
map("n", "<C-Up>", ":resize -2<CR>")
map("n", "<C-Down>", ":resize +2<CR>")
map("n", "<C-Left>", ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- Move between buffers
map("n", "H", ":bprevious<CR>")
map("n", "L", ":bnext<CR>")

-- Stay in visual mode while indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move selected text up and down (like VSCode)
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered when navigating search results
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Keep cursor in place when joining lines
map("n", "J", "mzJ`z")

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Better paste (won't replace register)
map("v", "p", '"_dP')

-- Copy to system clipboard
map("n", "<leader>y", '"+y')
map("v", "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')

-- Delete without yanking
map("n", "<leader>d", '"_d')
map("v", "<leader>d", '"_d')

-- Quick save
map("n", "<C-s>", ":w<CR>")
map("i", "<C-s>", "<ESC>:w<CR>")

-- Disable arrow keys (training wheels)
-- map("n", "<Up>", "<NOP>")
-- map("n", "<Down>", "<NOP>")
-- map("n", "<Left>", "<NOP>")
-- map("n", "<Right>", "<NOP>")

-- Create new lines without entering insert mode
map("n", "<leader>o", "o<ESC>")
map("n", "<leader>O", "O<ESC>")

-- Quick quit
map("n", "<leader>q", ":q<CR>")
map("n", "<leader>Q", ":qa!<CR>")

-- Quick buffer management
map("n", "<leader>bd", ":bd<CR>")
map("n", "<leader>bn", ":bnext<CR>")
map("n", "<leader>bp", ":bprevious<CR>")

-- Split windows like in VSCode
map("n", "<leader>\\", ":vsplit<CR>")
map("n", "<leader>-", ":split<CR>")

-- Quick escape terminal mode
map("t", "<ESC>", "<C-\\><C-n>")

-- Quick access to common actions
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>wa", ":wa<CR>")

-- Clear search highlighting
map("n", "<ESC>", ":noh<CR>")

-- Move lines in normal mode
map("n", "<A-j>", ":m .+1<CR>==")
map("n", "<A-k>", ":m .-2<CR>==")
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi")

-- Quick diagnostics navigation
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "<leader>e", vim.diagnostic.open_float)
map("n", "<leader>cr", vim.lsp.buf.rename) -- Common VSCode pattern