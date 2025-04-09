return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local nvim_tree = require("nvim-tree")
      local api = require("nvim-tree.api")

      -- Configure nvim-tree
      nvim_tree.setup({
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
            },
          },
        },
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
        on_attach = function(bufnr)
          local opts = { noremap = true, silent = true, buffer = bufnr }

          -- Keybindings for nvim-tree
          vim.keymap.set("n", "<leader>e", api.tree.toggle, opts) -- Toggle file tree
          vim.keymap.set("n", "<leader>r", api.tree.reload, opts) -- Reload file tree
          vim.keymap.set("n", "<leader>n", api.node.open.edit, opts) -- Open file or directory

          -- Right-click context menu
          vim.keymap.set("n", "<RightMouse>", function()
            local node = api.tree.get_node_under_cursor()
            if node then
              vim.ui.select({
                "Open to the Side",
                "Open With...",
                "Reveal in Finder",
                "Select for Compare",
                "Open Timeline",
                "Copilot",
                "Cut",
                "Copy",
                "Copy Path",
                "Copy Relative Path",
                "Rename",
                "Delete",
                "Add to .gitignore",
              }, {
                prompt = "File Actions:",
              }, function(choice)
                if choice == "Open to the Side" then
                  api.node.open.vertical()
                elseif choice == "Open With..." then
                  vim.cmd("echo 'Open With not implemented yet'")
                elseif choice == "Reveal in Finder" then
                  vim.fn.system({ "open", node.absolute_path })
                elseif choice == "Select for Compare" then
                  vim.cmd("echo 'Select for Compare not implemented yet'")
                elseif choice == "Open Timeline" then
                  vim.cmd("echo 'Open Timeline not implemented yet'")
                elseif choice == "Copilot" then
                  vim.cmd("echo 'Copilot not implemented yet'")
                elseif choice == "Cut" then
                  vim.cmd("echo 'Cut not implemented yet'")
                elseif choice == "Copy" then
                  vim.fn.setreg("+", node.absolute_path)
                elseif choice == "Copy Path" then
                  vim.fn.setreg("+", node.absolute_path)
                elseif choice == "Copy Relative Path" then
                  vim.fn.setreg("+", vim.fn.fnamemodify(node.absolute_path, ":."))
                elseif choice == "Rename" then
                  api.fs.rename(node.absolute_path)
                elseif choice == "Delete" then
                  api.fs.remove(node.absolute_path)
                elseif choice == "Add to .gitignore" then
                  vim.cmd("echo 'Add to .gitignore not implemented yet'")
                end
              end)
            end
          end, opts)
        end,
      })

      -- Open nvim-tree by default in the current working directory
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          -- If a directory is passed, open nvim-tree
          if vim.fn.isdirectory(data.file) == 1 then
            vim.cmd.cd(data.file)
            require("nvim-tree.api").tree.open()
          elseif data.file == "" and #vim.fn.getbufinfo({ buflisted = true }) == 0 then
            -- If no file is passed and no buffers are open, show alpha
            require("alpha").start()
          end
        end,
      })
    end,
  },
}
