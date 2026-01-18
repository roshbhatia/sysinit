return {
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
          "permissions",
          "size",
          "mtime",
        },
        constrain_cursor = "name",
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
        use_default_keymaps = false,
        keymaps = {
          ["-"] = { "actions.parent", mode = "n" },
          ["<CR>"] = "actions.select",
          ["<localleader>p"] = "actions.preview",
          ["<localleader>r"] = "actions.refresh",
          ["<localleader>s"] = { "actions.select", opts = { horizontal = true } },
          ["<localleader>v"] = { "actions.select", opts = { vertical = true } },
          ["_"] = { "actions.open_cwd", mode = "n" },
          ["`"] = { "actions.cd", mode = "n" },
          ["g."] = { "actions.toggle_hidden", mode = "n" },
          ["g?"] = { "actions.show_help", mode = "n" },
          ["g\\"] = { "actions.toggle_trash", mode = "n" },
          ["gs"] = { "actions.change_sort", mode = "n" },
          ["gx"] = "actions.open_external",
          ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
          ["q"] = { "actions.close", mode = "n" },
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
          "<leader>ee",
          function()
            vim.cmd("Oil")
          end,
          desc = "Explore current directory",
        },
        {
          "<leader>eE",
          function()
            vim.cmd("Oil .")
          end,
          desc = "Explore project root",
        },
      }
    end,
  },
}
