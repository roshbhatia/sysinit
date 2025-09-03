local M = {}

M.plugins = {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "folke/snacks.nvim",
    },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "icon",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        watch_for_changes = true,
        view_options = {
          show_hidden = true,
        },
        float = {
          border = "rounded",
        },
        case_insensitive = true,
        keymaps = {
          ["q"] = { "actions.close", mode = "n" },
          ["<localleader>v"] = { "actions.select", opts = { vertical = true } },
          ["<localleader>s"] = { "actions.select", opts = { horizontal = true } },
        },
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        callback = function(event)
          if event.data.actions.type == "move" then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })
    end,
    keys = function()
      return {
        {
          "<leader>eb",
          function()
            vim.cmd("Oil")
          end,
          desc = "Toggle explore in filesystem buffer",
        },
        {
          "<leader>ee",
          function()
            vim.cmd("Oil --float --preview")
          end,
          desc = "Toggle explore in filesystem buffer (float)",
        },

        {
          "<leader>eE",
          function()
            vim.cmd("Oil --float --preview .")
          end,
          desc = "Toggle explore in filesystem buffer in project root (float)",
        },
      }
    end,
  },
}

return M
