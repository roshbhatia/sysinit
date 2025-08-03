local M = {}

local uv = vim.loop
local function debounce(fn, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = uv.new_timer()
    timer:start(
      delay,
      0,
      vim.schedule_wrap(function()
        fn(unpack(args))
      end)
    )
  end
end

M.plugins = {
  {
    "yaocccc/nvim-foldsign",
    config = function()
      local foldsign = require("nvim-foldsign")
      foldsign.setup({
        offset = -3,
        foldsigns = {
          open = "*",
          close = "-",
          seps = { "│", "┃" },
        },
        enabled = true,
      })

      local original_foldsign = foldsign.foldsign
      foldsign.foldsign = debounce(function()
        local win = vim.api.nvim_get_current_win()
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative ~= "" then
          vim.api.nvim_buf_clear_namespace(0, foldsign.ns, 0, -1)
          return
        end
        original_foldsign()
      end, 50)
    end,
  },
}

return M
