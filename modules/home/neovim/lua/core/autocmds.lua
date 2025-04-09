-- Core autocommands

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General Settings Group
local general = augroup("General", { clear = true })

-- Disable commenting on new line
autocmd("BufEnter", {
  group = general,
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Highlight on yank
autocmd("TextYankPost", {
  group = general,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
  end,
})

-- Resize splits when window resized
autocmd("VimResized", {
  group = general,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Auto create dir when saving a file where dir doesn't exist
autocmd("BufWritePre", {
  group = general,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Go to last location when opening a buffer
autocmd("BufReadPost", {
  group = general,
  pattern = "*",
  callback = function()
    local exclude = { "gitcommit" }
    local buf = vim.api.nvim_get_current_buf()
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
autocmd("FileType", {
  group = general,
  pattern = {
    "help",
    "qf",
    "startuptime",
    "lspinfo",
    "checkhealth",
    "man",
    "TelescopePrompt",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Faster window switching
autocmd("FocusGained", {
  group = general,
  command = "checktime",
})

-- File Type Settings Group
local filetype_settings = augroup("FiletypeSettings", { clear = true })

-- Set indentation for specific filetypes
autocmd("FileType", {
  group = filetype_settings,
  pattern = { "lua", "javascript", "typescript", "json", "yaml", "markdown", "html", "css" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

autocmd("FileType", {
  group = filetype_settings,
  pattern = { "python", "rust", "go" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- Go
autocmd("FileType", {
  group = filetype_settings,
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

-- Markdown
autocmd("FileType", {
  group = filetype_settings,
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Make help windows easier to identify
autocmd("FileType", {
  group = filetype_settings,
  pattern = "help",
  callback = function()
    vim.cmd("wincmd L")
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Terminal Settings Group
local terminal_settings = augroup("TerminalSettings", { clear = true })

-- Auto enter insert mode when opening terminal
autocmd("TermOpen", {
  group = terminal_settings,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- Startify Settings Group
local startify_settings = augroup("StartifySettings", { clear = true })

-- Disable indentation in Startify
autocmd("FileType", {
  group = startify_settings,
  pattern = "startify",
  callback = function()
    -- Use pcall to avoid errors if plugins aren't loaded yet
    pcall(function()
      vim.cmd("IBLDisable")
    end)
    vim.opt_local.cursorline = true
    vim.opt_local.cursorcolumn = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.colorcolumn = ""
  end,
})

-- CHADTree Settings
autocmd("FileType", {
  group = augroup("CHADTreeSettings", { clear = true }),
  pattern = "CHADTree",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Format on save
local format_on_save = augroup("FormatOnSave", { clear = true })

autocmd("BufWritePre", {
  group = format_on_save,
  callback = function()
    -- Check if LSP formatting is available
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    local can_format = false
    for _, client in ipairs(clients) do
      if client.server_capabilities.documentFormattingProvider then
        can_format = true
        break
      end
    end
    
    if can_format then
      -- Use pcall to avoid errors if the buffer isn't properly set up
      pcall(function()
        vim.lsp.buf.format({ async = false })
      end)
    end
  end,
})