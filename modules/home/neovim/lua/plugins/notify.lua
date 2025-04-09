return {
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        stages = "fade_in_slide_out",
        timeout = 3000,
        background_colour = "#000000",
      })

      -- Set as the default notification handler
      vim.notify = notify
    end,
  },
}
