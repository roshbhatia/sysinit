return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      Snacks.keymap.set("n", "<c-leftmouse>", mc.handleMouse, { desc = "Multi-cursor mouse" })
      Snacks.keymap.set("n", "<c-leftdrag>", mc.handleMouseDrag, { desc = "Multi-cursor drag" })
      Snacks.keymap.set("n", "<c-leftrelease>", mc.handleMouseRelease, { desc = "Multi-cursor release" })

      Snacks.keymap.set({ "n", "x" }, "X", mc.toggleCursor, { desc = "Toggle cursor" })

      Snacks.keymap.set({ "n", "x" }, "<C-x>", mc.clearCursors, { desc = "Clear cursors" })

      vim.api.nvim_create_user_command("MultiCursorClear", function()
        mc.clearCursors()
      end, {
        desc = "Clear all multi-cursors",
      })

      vim.api.nvim_create_user_command("MultiCursorEnable", function()
        mc.enableCursors()
      end, {
        desc = "Enable multi-cursors",
      })

      vim.api.nvim_create_user_command("MultiCursorNext", function()
        mc.nextCursor()
      end, {
        desc = "Next multi-cursor",
      })

      vim.api.nvim_create_user_command("MultiCursorPrev", function()
        mc.prevCursor()
      end, {
        desc = "Previous multi-cursor",
      })

      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { reverse = true })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledCursor", { reverse = true })
    end,
  },
}
