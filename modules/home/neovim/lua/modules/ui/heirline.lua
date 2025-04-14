local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    'rebelot/heirline.nvim',
    dependencies = { 
      'nvim-tree/nvim-web-devicons',
      'lewis6991/gitsigns.nvim'
    },
    config = function()
      local conditions = require("heirline.conditions")
      local utils = require("heirline.utils")
      
      -- Color constants for the statusline
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
        git_del = utils.get_highlight("DiffDelete").fg,
        git_add = utils.get_highlight("DiffAdd").fg,
        git_change = utils.get_highlight("DiffChange").fg,
      }
      
      -- Vim mode component
      local ViMode = {
        init = function(self)
          self.mode = vim.fn.mode(1)
        end,
        static = {
          mode_names = {
            n = "NORMAL",
            no = "OP-PENDING",
            nov = "OP-PENDING",
            noV = "OP-PENDING",
            ["no\22"] = "OP-PENDING",
            niI = "NORMAL",
            niR = "NORMAL",
            niV = "NORMAL",
            v = "VISUAL",
            V = "V-LINE",
            ["\22"] = "V-BLOCK",
            s = "SELECT",
            S = "S-LINE",
            ["\19"] = "S-BLOCK",
            i = "INSERT",
            ic = "INSERT",
            ix = "INSERT",
            R = "REPLACE",
            Rc = "REPLACE",
            Rv = "V-REPLACE",
            Rx = "REPLACE",
            c = "COMMAND",
            cv = "EX",
            ce = "EX",
            r = "PROMPT",
            rm = "MORE",
            ["r?"] = "CONFIRM",
            ["!"] = "SHELL",
            t = "TERMINAL",
          },
          mode_colors = {
            n = "green",
            i = "blue",
            v = "purple",
            V = "purple",
            ["\22"] = "purple",
            c = "orange",
            s = "purple",
            S = "purple",
            ["\19"] = "purple",
            R = "red",
            r = "red",
            ["!"] = "cyan",
            t = "cyan",
          }
        },
        provider = function(self)
          return " %2(" .. self.mode_names[self.mode] .. "%) "
        end,
        hl = function(self)
          local mode = self.mode:sub(1, 1)
          return { fg = "bright_bg", bg = self[self.mode_colors[mode]], bold = true }
        end,
        update = {
          "ModeChanged",
          pattern = "*:*",
          callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
          end),
        },
      }
      
      -- Git component
      local Git = {
        condition = conditions.is_git_repo,
        init = function(self)
          self.status_dict = vim.b.gitsigns_status_dict or {}
          self.has_changes = (self.status_dict.added or 0) ~= 0 
                           or (self.status_dict.removed or 0) ~= 0 
                           or (self.status_dict.changed or 0) ~= 0
        end,
        hl = { fg = "orange", bg = "bright_bg" },
        {
          provider = function(self)
            return " " .. self.status_dict.head .. " "
          end,
          hl = { bold = true }
        },
        {
          condition = function(self)
            return self.has_changes
          end,
          provider = "("
        },
        {
          provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("+" .. count)
          end,
          hl = { fg = "git_add" },
        },
        {
          provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("-" .. count)
          end,
          hl = { fg = "git_del" },
        },
        {
          provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("~" .. count)
          end,
          hl = { fg = "git_change" },
        },
        {
          condition = function(self)
            return self.has_changes
          end,
          provider = ")",
        },
      }
      
      -- Diagnostics component
      local Diagnostics = {
        condition = conditions.has_diagnostics,
        static = {
          error_icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text,
          warn_icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text,
          info_icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text,
          hint_icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text,
        },
        init = function(self)
          self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
          self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
          self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
          self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        end,
        update = { "DiagnosticChanged", "BufEnter" },
        {
          provider = " ",
        },
        {
          provider = function(self)
            return self.errors > 0 and (self.error_icon .. " " .. self.errors .. " ")
          end,
          hl = { fg = "diag_error" },
        },
        {
          provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. " " .. self.warnings .. " ")
          end,
          hl = { fg = "diag_warn" },
        },
        {
          provider = function(self)
            return self.info > 0 and (self.info_icon .. " " .. self.info .. " ")
          end,
          hl = { fg = "diag_info" },
        },
        {
          provider = function(self)
            return self.hints > 0 and (self.hint_icon .. " " .. self.hints .. " ")
          end,
          hl = { fg = "diag_hint" },
        },
      }
      
      -- File info
      local FileInfo = {
        {
          provider = function()
            local filename = vim.fn.expand("%:t")
            local extension = vim.fn.expand("%:e")
            local icon = require("nvim-web-devicons").get_icon(filename, extension)
            return (icon and icon .. " " or "") .. filename .. " "
          end,
          hl = { fg = "bright_fg", bg = "bright_bg" },
        },
        {
          provider = function()
            local readonly = vim.bo.readonly
            local modified = vim.bo.modified
            return (readonly and " " or "") .. (modified and " " or "")
          end,
          hl = function()
            return { fg = "blue", bg = "bright_bg" }
          end
        },
      }
      
      -- Ruler component
      local Ruler = {
        provider = "%7(%l/%L%):%2c %P",
        hl = { fg = "bright_fg", bg = "bright_bg" },
      }
      
      local TerminalName = {
        provider = function()
          local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
          return " " .. tname
        end,
        hl = { fg = "bright_fg", bg = "bright_bg" },
      }
      
      -- LSP component
      local LSPActive = {
        condition = conditions.lsp_attached,
        provider = function()
          local names = {}
          for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          return " " .. table.concat(names, " ") .. " "
        end,
        hl = { fg = "green", bg = "bright_bg", bold = true },
      }
      
      -- Separator component
      local Space = { provider = " " }
      local Align = { provider = "%=" }
      
      -- Filetype component
      local FileType = {
        provider = function()
          return " " .. vim.bo.filetype .. " "
        end,
        hl = { fg = "bright_fg", bg = "bright_bg" },
      }
      
      -- Default statusline
      local DefaultStatusline = {
        ViMode,
        Space,
        FileInfo,
        Align,
        Git,
        Space,
        Diagnostics,
        Align,
        LSPActive,
        Space,
        FileType,
        Space,
        Ruler,
      }
      
      -- Terminal statusline
      local TerminalStatusline = {
        ViMode,
        Space,
        TerminalName,
        Align,
        Ruler,
      }
      
      -- Setting up statusline
      local statuslines = {
        fallthrough = false,
        {
          condition = function()
            return conditions.buffer_matches({
              buftype = { "terminal" },
            })
          end,
          TerminalStatusline,
        },
        {
          condition = function()
            return true
          end,
          DefaultStatusline,
        },
      }
      
      require("heirline").setup({
        statusline = statuslines,
        opts = {
          colors = colors,
        }
      })
    end
  }
}

function M.setup()
  local commander = require("commander")
  
  -- Register heirline commands with commander
  commander.add({
    {
      desc = "Toggle Statusline",
      cmd = function()
        local ls = vim.opt.laststatus:get()
        if ls == 0 then
          vim.opt.laststatus = 2
        elseif ls == 2 then
          vim.opt.laststatus = 0
        end
        vim.cmd("redrawstatus")
      end,
      keys = { "n", "<leader>ts" },
      cat = "UI"
    }
  })
  
  -- Register verification steps
  verify.register_verification("heirline", {
    {
      desc = "Statusline Display",
      command = "Check bottom of screen",
      expected = "Should show a statusline with mode, file info, and other details"
    },
    {
      desc = "Toggle Statusline",
      command = "<leader>ts",
      expected = "Should toggle the statusline visibility"
    }
  })
end

return M