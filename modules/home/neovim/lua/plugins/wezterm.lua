return {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = function()
      local wezterm = require("wezterm")

      -- Keybindings for managing splits and panes
      vim.keymap.set("n", "<leader>wl", function()
        wezterm.split_pane.horizontal({ right = true, percent = 20, program = { "nvim" } })
      end, { desc = "Open right pane in WezTerm" })

      vim.keymap.set("n", "<leader>wm", function()
        wezterm.split_pane.horizontal({ left = true, percent = 60, program = { "nvim" } })
      end, { desc = "Open middle pane in WezTerm" })

      vim.keymap.set("n", "<leader>we", function()
        wezterm.split_pane.horizontal({ left = true, percent = 20, program = { "wezterm" } })
      end, { desc = "Open left pane in WezTerm" })

      -- Command to spawn a new task in WezTerm
      vim.api.nvim_create_user_command("WeztermSpawn", function(opts)
        wezterm.spawn({ program = opts.args })
      end, { nargs = "+" })
    end,
  },
}
