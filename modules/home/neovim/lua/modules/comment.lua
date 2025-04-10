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

      -- Custom keymaps to avoid gc/gcc overlap
      vim.keymap.set('n', '<leader>c', function()
        require("Comment.api").toggle.linewise.current()
      end, { desc = "Toggle comment line" })

      vim.keymap.set('x', '<leader>c', function()
        local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end, { desc = "Toggle comment" })
    end,
  }
}

function M.setup()
  -- Any additional setup logic for comments
end

return M
