-- Heavily pulls from multinput.nvim: https://github.com/r0nsha/multinput.nvim
local M = {}
local history = require("sysinit.utils.ai.history")
local placeholders = require("sysinit.utils.ai.placeholders")

-- Utility functions for input handling
local utils = {
  set_options = function(options, opts)
    for k, v in pairs(options) do
      vim.api.nvim_set_option_value(k, v, opts)
    end
  end,

  set_option_if_globally_enabled = function(option, winnr)
    if vim.api.nvim_get_option_value(option, { scope = "global" }) then
      vim.api.nvim_set_option_value(option, true, { win = winnr })
    end
  end,

  clamp = function(value, min, max)
    return math.min(math.max(value, min), max)
  end,

  split_wrapped_lines = function(text, width)
    if text == "" then
      return {}
    end

    local lines = {}
    local textlen = vim.fn.strchars(text, true)

    local i = 0
    while i < textlen do
      local len = i + width <= textlen and width or textlen - i
      local new_line = vim.fn.strcharpart(text, i, len)
      table.insert(lines, new_line)
      i = i + len
    end

    return lines
  end,

  get_linenr_width = function(winnr, bufnr)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local line_digits = math.floor(math.log10(math.max(1, line_count))) + 1
    local numberwidth = vim.api.nvim_get_option_value("numberwidth", { win = winnr })
    return math.max(line_digits, numberwidth)
  end,
}

local MultilineInput = {}
local group = vim.api.nvim_create_augroup("sysinit.ai.input", { clear = true })

function MultilineInput:new(config, on_confirm)
  local i = {
    config = config,
    on_confirm = on_confirm or function() end,
  }
  setmetatable(i, self)
  self.__index = self
  return i
end

function MultilineInput:open(default)
  self.mode = vim.fn.mode()
  self.parent_win = vim.api.nvim_get_current_win()

  local cursor_row = vim.api.nvim_win_get_cursor(self.parent_win)[1]
  local win_config = (cursor_row <= 3) and { anchor = "NW", row = 1 } or { anchor = "SW", row = 0 }
  self.config.win = vim.tbl_deep_extend("force", self.config.win, win_config)

  -- Create buffer and window
  self.bufnr = vim.api.nvim_create_buf(false, true)
  utils.set_options({
    filetype = "ai_terminals_input",
    buftype = "prompt",
    bufhidden = "wipe",
    modifiable = true,
  }, { buf = self.bufnr })
  vim.fn.prompt_setprompt(self.bufnr, "")

  self.winnr = vim.api.nvim_open_win(self.bufnr, true, self.config.win)
  utils.set_options({
    wrap = true,
    linebreak = true,
    showbreak = "  ",
    winhighlight = "Search:None",
  }, { win = self.winnr })

  -- Set default value
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, { default })

  self:resize()
  self:autocmds()
  self:mappings()

  -- Add placeholder syntax highlighting
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(self.bufnr) then
      vim.fn.matchadd("Special", "+[%w_]\\+")
    end
  end)

  vim.api.nvim_win_call(self.winnr, function()
    vim.cmd("startinsert!")
  end)
end

function MultilineInput:close(result)
  vim.cmd("stopinsert")
  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
  end
  if vim.api.nvim_win_is_valid(self.parent_win) then
    vim.api.nvim_set_current_win(self.parent_win)
    if self.mode == "i" then
      vim.cmd("startinsert")
    end
  end
  self.on_confirm(result)
end

function MultilineInput:set_numbers(height)
  if self.config.numbers == "always" or (self.config.numbers == "multiline" and height > 1) then
    utils.set_option_if_globally_enabled("number", self.winnr)
    utils.set_option_if_globally_enabled("relativenumber", self.winnr)
  end

  return vim.api.nvim_get_option_value("number", { win = self.winnr })
    or vim.api.nvim_get_option_value("relativenumber", { win = self.winnr })
end

function MultilineInput:set_size(width, height)
  local h = utils.clamp(height, self.config.height.min, self.config.height.max)
  vim.api.nvim_win_set_height(self.winnr, h)

  local w = utils.clamp(width + self.config.padding, self.config.width.min, self.config.width.max)

  local has_numbers = self:set_numbers(h)
  w = has_numbers and w + utils.get_linenr_width(self.winnr, self.bufnr) or w
  w = w + 2
  vim.api.nvim_win_set_width(self.winnr, w)
end

function MultilineInput:resize()
  local text = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
  local line = table.concat(text, "")

  if line == "" then
    self:set_size(0, 1)
    return
  end

  local lines = utils.split_wrapped_lines(line, self.config.width.max)
  local lens = vim.tbl_map(function(l)
    return vim.fn.strdisplaywidth(l)
  end, lines)

  self:set_size(math.max(unpack(lens)), #lines)
end

function MultilineInput:autocmds()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = self.bufnr,
    callback = function()
      self:resize()
    end,
  })
end

function MultilineInput:mappings()
  local function map(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = self.bufnr })
  end

  local function confirm()
    self:close(vim.api.nvim_buf_get_lines(self.bufnr, 0, 1, false)[1])
  end

  -- Submit on Enter, add newline on Shift+Enter
  map({ "n", "v" }, "<cr>", confirm)
  map("i", "<cr>", confirm)
  map("i", "<s-cr>", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, false, true), "n", false)
  end)

  map("n", "<esc>", function()
    self:close()
  end)

  map("n", "q", function()
    self:close()
  end)
end

function M.create_input(termname, agent_icon, opts)
  opts = opts or {}
  local action_name = opts.action or "Ask"
  local title = string.format("%s  %s", agent_icon or "", action_name)

  local context = require("sysinit.utils.ai.context")
  local initial_state = context.new()

  local hist = history.load_history(termname)
  local current_history_index = history.get_current_history_index()
  history.set_current_history_index(termname, #hist + 1)

  local config = {
    numbers = "never",
    padding = 5,
    width = { min = 20, max = 80 },
    height = { min = 1, max = 10 },
    win = {
      title = title,
      style = "minimal",
      focusable = true,
      relative = "cursor",
      border = "rounded",
      col = 0,
      width = 1,
      height = 1,
    },
  }

  local input = MultilineInput:new(config, function(value)
    if opts.on_confirm and value and value ~= "" then
      history.save_to_history(termname, value)
      opts.on_confirm(placeholders.apply(value, initial_state))
    end
  end)

  -- Add history navigation keymaps after input is opened
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(input.bufnr) then
      -- Navigate forward in history (older)
      local function history_forward()
        if current_history_index[termname] < #hist then
          current_history_index[termname] = current_history_index[termname] + 1
          local entry = hist[current_history_index[termname]]
          if entry then
            vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, true, { entry.prompt })
            input:resize()
          end
        end
      end

      -- Navigate backward in history (newer)
      local function history_backward()
        if current_history_index[termname] > 1 then
          current_history_index[termname] = current_history_index[termname] - 1
          local entry = hist[current_history_index[termname]]
          if entry then
            vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, true, { entry.prompt })
            input:resize()
          end
        elseif current_history_index[termname] == 1 then
          current_history_index[termname] = #hist + 1
          vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, true, { "" })
          input:resize()
        end
      end

      -- Up/Down for history navigation in insert mode
      vim.keymap.set("i", "<Up>", history_backward, { buffer = input.bufnr, desc = "History backward" })
      vim.keymap.set("i", "<Down>", history_forward, { buffer = input.bufnr, desc = "History forward" })

      -- Ctrl-j/k as alternatives
      vim.keymap.set("i", "<C-j>", history_forward, { buffer = input.bufnr, desc = "History forward" })
      vim.keymap.set("i", "<C-k>", history_backward, { buffer = input.bufnr, desc = "History backward" })
    end
  end)

  input:open(opts.default or "")
end

return M
