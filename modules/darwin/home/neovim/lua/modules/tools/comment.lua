-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/numToStr/Comment.nvim/refs/heads/master/doc/Comment.txt"
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

return M