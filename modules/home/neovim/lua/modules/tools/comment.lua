local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "numToStr/Comment.nvim",
    lazy = false,
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
      config = true
    },
    opts = {
      mappings = {
        basic = false,
        extra = false,
      },
      pre_hook = function(ctx)
        -- Enable comment strings for treesitter
        local U = require("Comment.utils")
        local location = nil
        if ctx.ctype == U.ctype.block then
          location = require("ts_context_commentstring.utils").get_cursor_location()
        elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
          location = require("ts_context_commentstring.utils").get_visual_start_location()
        end

        local treesitter_ok, ts_context_commentstring = pcall(require, "ts_context_commentstring.internal")
        if treesitter_ok then
          return ts_context_commentstring.calculate_commentstring({
            key = ctx.ctype == U.ctype.line and "__default" or "__multiline",
            location = location,
          })
        end
      end,
    },
    config = function(_, opts)
      require("Comment").setup(opts)
    end
  }
}

function M.setup()
  local commander = require("commander")
  
  -- Register comment commands with commander
  commander.add({
    {
      desc = "Toggle Comment Line",
      cmd = function()
        require("Comment.api").toggle.linewise.current()
      end,
      keys = { "n", "<leader>c" },
      cat = "Comment"
    },
    {
      desc = "Toggle Comment Selection",
      cmd = function()
        local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end,
      keys = { "x", "<leader>c" },
      cat = "Comment"
    },
    {
      desc = "Toggle Block Comment",
      cmd = function()
        require("Comment.api").toggle.blockwise.current()
      end,
      keys = { "n", "<leader>cb" },
      cat = "Comment"
    },
    {
      desc = "Toggle Block Comment Selection",
      cmd = function()
        local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        require("Comment.api").toggle.blockwise(vim.fn.visualmode())
      end,
      keys = { "x", "<leader>cb" },
      cat = "Comment"
    }
  })
  
  -- Register verification steps
  verify.register_verification("comment", {
    {
      desc = "Line Comment Toggle",
      command = "<leader>c",
      expected = "Should toggle comment on current line"
    },
    {
      desc = "Block Comment Toggle",
      command = "<leader>cb",
      expected = "Should toggle block comment on current line"
    },
    {
      desc = "Visual Comment Toggle",
      command = "Visual mode + <leader>c",
      expected = "Should toggle comment on selected lines"
    },
    {
      desc = "Commander Integration",
      command = ":Telescope commander filter cat=Comment",
      expected = "Should show Comment commands in Commander palette"
    }
  })
end

return M