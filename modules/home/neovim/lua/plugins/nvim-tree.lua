return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local nvim_tree = require("nvim-tree")

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
          local api = require("nvim-tree.api")
          local opts = { noremap = true, silent = true, buffer = bufnr }

          -- Keybindings for nvim-tree
          vim.keymap.set("n", "<leader>e", api.tree.toggle, opts) -- Toggle file tree
          vim.keymap.set("n", "<leader>r", api.tree.reload, opts) -- Reload file tree
          vim.keymap.set("n", "<leader>n", api.node.open.edit, opts) -- Open file or directory
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
