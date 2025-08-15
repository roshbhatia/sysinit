local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

M.plugins = {
  {
    "azorng/goose.nvim",
    enabled = agents_config.agents.enabled and agents_config.agents.goose.enabled,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    lazy = true,
    config = function()
      require("goose").setup({
        keymap = {
          global = {
            toggle = "<leader>kk",
            open_input = "<leader>ki",
            open_input_new_session = "<leader>kK",
            open_output = "<leader>ko",
            toggle_focus = "<leader>kt",
            close = "<leader>kq",
            toggle_fullscreen = "<leader>kf",
            select_session = "<leader>ks",
            goose_mode_chat = "<leader>kmc",
            goose_mode_auto = "<leader>kma",
            configure_provider = "<leader>kp",
            diff_open = "<leader>kd",
            diff_next = "<leader>k]",
            diff_prev = "<leader>k[",
            diff_close = "<leader>kc",
            diff_revert_all = "<leader>kra",
            diff_revert_this = "<leader>krt",
          },
          window = {
            submit = "<CR>",
            submit_insert = "<S-CR>",
            close = "<esc>",
            stop = "<C-c>",
            next_message = "]]",
            prev_message = "[[",
            mention_file = "@",
            toggle_pane = "<tab>",
            prev_prompt_history = "<up>",
            next_prompt_history = "<down>",
          },
        },
        prefered_picker = "telescope",
      })
    end,
  },
}

return M

