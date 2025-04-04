-- Heirline configuration for statusline, winbar, bufferline, and statuscolumn
local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

-- Statusline components
local Align = { provider = "%=" }
local Space = { provider = " " }

-- Colors that will be used by the statusline
local colors = {
  bright_bg = utils.get_highlight("Folded").bg,
  bright_fg = utils.get_highlight("Folded").fg,
  red = utils.get_highlight("DiagnosticError").fg,
  dark_red = utils.get_highlight("DiffDelete").bg,
  green = utils.get_highlight("String").fg,
  blue = utils.get_highlight("Function").fg,
  gray = utils.get_highlight("NonText").fg,
  orange = utils.get_highlight("Constant").fg,
  purple = utils.get_highlight("Statement").fg,
  cyan = utils.get_highlight("Special").fg,
  diag_warn = utils.get_highlight("DiagnosticWarn").fg,
  diag_error = utils.get_highlight("DiagnosticError").fg,
  diag_hint = utils.get_highlight("DiagnosticHint").fg,
  diag_info = utils.get_highlight("DiagnosticInfo").fg,
  git_add = utils.get_highlight("diffAdded").fg,
  git_change = utils.get_highlight("diffChanged").fg,
  git_del = utils.get_highlight("diffRemoved").fg,
}

-- ViMode component
local ViMode = {
  init = function(self)
    self.mode = vim.fn.mode(1)
  end,
  static = {
    mode_names = {
      n = "NORMAL",
      no = "NORMAL",
      nov = "NORMAL",
      noV = "NORMAL",
      ["no\22"] = "NORMAL",
      niI = "NORMAL",
      niR = "NORMAL",
      niV = "NORMAL",
      nt = "NORMAL",
      v = "VISUAL",
      vs = "VISUAL",
      V = "V-LINE",
      Vs = "V-LINE",
      ["\22"] = "V-BLOCK",
      ["\22s"] = "V-BLOCK",
      s = "SELECT",
      S = "S-LINE",
      ["\19"] = "S-BLOCK",
      i = "INSERT",
      ic = "INSERT",
      ix = "INSERT",
      R = "REPLACE",
      Rc = "REPLACE",
      Rx = "REPLACE",
      Rv = "REPLACE",
      Rvc = "REPLACE",
      Rvx = "REPLACE",
      c = "COMMAND",
      cv = "EX",
      r = "PROMPT",
      rm = "MORE",
      ["r?"] = "CONFIRM",
      ["!"] = "SHELL",
      t = "TERMINAL",
    },
    mode_colors = {
      n = "blue",
      i = "green",
      v = "cyan",
      V = "cyan",
      ["\22"] = "cyan",
      c = "orange",
      s = "purple",
      S = "purple",
      ["\19"] = "purple",
      R = "red",
      r = "red",
      ["!"] = "red",
      t = "red",
    },
  },
  provider = function(self)
    return " %2(" .. self.mode_names[self.mode] .. "%)"
  end,
  hl = function(self)
    local mode = self.mode:sub(1, 1)
    return { fg = self[self.mode_colors[mode]], bold = true }
  end,
  update = {
    "ModeChanged",
    pattern = "*:*",
    callback = vim.schedule_wrap(function()
      vim.cmd("redrawstatus")
    end),
  },
}

-- File info component showing name, modification status
local FileInfo = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
  hl = { fg = utils.get_highlight("Directory").fg },
  
  -- Filename
  {
    provider = function(self)
      local filename = vim.fn.fnamemodify(self.filename, ":t")
      if filename == "" then return "[No Name]" end
      return filename
    end,
  },
  
  -- File flags
  {
    provider = function()
      if vim.bo.modified then
        return " [+]"
      elseif vim.bo.modifiable == false or vim.bo.readonly == true then
        return " [-]"
      end
      return ""
    end,
    hl = { fg = "orange" },
  },
  
  -- File type
  {
    provider = function()
      local filetype = vim.bo.filetype
      if filetype == "" then
        return ""
      else
        return " (" .. filetype .. ")"
      end
    end,
    hl = { fg = "gray", italic = true },
  },
}

-- Git info component
local Git = {
  condition = conditions.is_git_repo,
  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
  end,
  
  -- Git branch name
  {
    provider = function(self)
      return "  " .. self.status_dict.head .. " "
    end,
    hl = { fg = "purple", bold = true },
  },
  
  -- Git changes
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = function(self)
      local count = self.status_dict.added or 0
      return count > 0 and ("+" .. count .. " ")
    end,
    hl = { fg = "git_add" },
  },
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = function(self)
      local count = self.status_dict.changed or 0
      return count > 0 and ("~" .. count .. " ")
    end,
    hl = { fg = "git_change" },
  },
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = function(self)
      local count = self.status_dict.removed or 0
      return count > 0 and ("-" .. count)
    end,
    hl = { fg = "git_del" },
  },
}

-- Diagnostics component
local Diagnostics = {
  condition = conditions.has_diagnostics,
  static = {
    error_icon = "  ",
    warn_icon = "  ",
    info_icon = "  ",
    hint_icon = "  ",
  },
  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,
  update = { "DiagnosticChanged", "BufEnter" },
  
  -- Error count
  {
    provider = function(self)
      return self.errors > 0 and (self.error_icon .. self.errors .. " ")
    end,
    hl = { fg = "diag_error" },
  },
  
  -- Warning count
  {
    provider = function(self)
      return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
    end,
    hl = { fg = "diag_warn" },
  },
  
  -- Info count
  {
    provider = function(self)
      return self.info > 0 and (self.info_icon .. self.info .. " ")
    end,
    hl = { fg = "diag_info" },
  },
  
  -- Hint count
  {
    provider = function(self)
      return self.hints > 0 and (self.hint_icon .. self.hints)
    end,
    hl = { fg = "diag_hint" },
  },
}

-- LSP component
local LSPActive = {
  condition = conditions.lsp_attached,
  update = {'LspAttach', 'LspDetach'},
  provider = function()
    local names = {}
    for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
      table.insert(names, server.name)
    end
    return "  " .. table.concat(names, ", ")
  end,
  hl = { fg = "green", bold = true },
}

-- Location component (line:column)
local Location = {
  provider = function()
    return " %l:%c/%L "
  end,
  hl = { fg = "blue" },
}

-- Cursor position percentage
local ScrollBar = {
  provider = function()
    local current_line = vim.fn.line(".")
    local total_lines = vim.fn.line("$")
    local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
    local line_ratio = current_line / total_lines
    local index = math.ceil(line_ratio * #chars)
    return chars[index]
  end,
  hl = { fg = "blue", bg = "bright_bg" },
}

-- Bufferline configuration
local BufferLine = {
  -- Bufferline initialization
  init = function(self)
    self.buffers = vim.tbl_filter(function(bufnr)
      return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
    end, vim.api.nvim_list_bufs())
    
    self.current_buffer = vim.api.nvim_get_current_buf()
  end,
  
  -- For each buffer, create a component
  {
    flexible = 3,
    {
      provider = function()
        local buflist = {}
        for i, bufnr in ipairs(vim.tbl_filter(function(bufnr)
          return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
        end, vim.api.nvim_list_bufs())) do
          -- Indicator to show if buffer is active
          local indicator = bufnr == vim.api.nvim_get_current_buf() and "●" or "○"
          -- Get the buffer name and cut it if it's too long
          local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
          -- Fallback for empty name
          if name == "" then name = "[No Name]" end
          
          -- Add buffer to the list
          table.insert(buflist, string.format(" %s %s ", indicator, name))
        end
        return table.concat(buflist, "|")
      end,
      hl = function(self)
        return { fg = "blue", bg = "bright_bg" }
      end,
    },
    -- Fallback if the line is too wide
    {
      provider = function()
        local bufcount = #vim.tbl_filter(function(bufnr)
          return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
        end, vim.api.nvim_list_bufs())
        return string.format(" %d buffers ", bufcount)
      end,
      hl = { fg = "blue", bg = "bright_bg" },
    },
  },
}

-- Setup full statusline
local StatusLine = {
  ViMode, Space, FileInfo, Space, Git, Align,
  Diagnostics, Space, LSPActive, Space, Location, ScrollBar
}

-- Setup full bufferline
local TabLine = {
  BufferLine,
}

-- Return the configuration
return {
  statusline = StatusLine,
  tabline = TabLine,
  opts = {
    colors = colors,
  }
}