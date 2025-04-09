-- Safely load nvim-tree
local status_ok_icons, icons = pcall(require, 'nvim-web-devicons')
if status_ok_icons then
  icons.setup()
end

local status_ok_tree, nvim_tree = pcall(require, 'nvim-tree')
if status_ok_tree then
  nvim_tree.setup({
    view = {
      width = 35,
      float = {
        enable = false,
        quit_on_focus_loss = true,
      },
    },
    renderer = {
      group_empty = true,
      highlight_git = true,
      icons = {
        show = {
          git = true,
          folder = true,
          file = true,
          folder_arrow = true,
        },
      },
    },
    update_focused_file = {
      enable = true,
      update_root = false,
    },
    diagnostics = {
      enable = true,
      show_on_dirs = true,
    },
    filters = {
      dotfiles = false,
    },
    actions = {
      use_system_clipboard = true,
      change_dir = {
        enable = true,
      },
      open_file = {
        resize_window = true,
        window_picker = {
          enable = true,
        },
      },
    },
    ui = {
      confirm = {
        remove = true,
        trash = true,
      },
    },
    live_filter = {
      prefix = "[FILTER]: ",
      always_show_folders = false,
    },
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      
      -- Default mappings
      api.config.mappings.default_on_attach(bufnr)
      
      -- Custom mappings for VSCode-like file operations
      local function opts(desc)
        return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end
      
      -- VSCode-like keymaps
      vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
      vim.keymap.set("n", "<C-c>", api.fs.copy.node, opts("Copy"))
      vim.keymap.set("n", "<C-x>", api.fs.cut, opts("Cut"))
      vim.keymap.set("n", "<C-v>", api.fs.paste, opts("Paste"))
      vim.keymap.set("n", "<F2>", api.fs.rename, opts("Rename"))
      vim.keymap.set("n", "<Delete>", api.fs.remove, opts("Delete"))
      vim.keymap.set("n", "d", api.fs.trash, opts("Trash"))
      vim.keymap.set("n", "<C-n>", api.fs.create, opts("Create"))
      vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
      vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
      vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
      vim.keymap.set("n", "<C-k>", api.node.navigate.sibling.prev, opts("Previous Sibling"))
      vim.keymap.set("n", "<C-j>", api.node.navigate.sibling.next, opts("Next Sibling"))
      vim.keymap.set("n", "P", function()
        local node = api.tree.get_node_under_cursor()
        print(node.absolute_path)
      end, opts("Print Node Path"))

      -- Right-click menu
      vim.keymap.set("n", "<RightMouse>", function()
        local node = api.tree.get_node_under_cursor()
        if not node then return end
        
        -- Create context menu options
        local context_menu = {
          { name = "1. Open", fn = function() api.node.open.edit() end },
          { name = "2. Open in Split", fn = function() api.node.open.horizontal() end },
          { name = "3. Open in Vertical Split", fn = function() api.node.open.vertical() end },
          { name = "4. --------------------", fn = function() end },
          { name = "5. Copy", fn = function() api.fs.copy.node() end },
          { name = "6. Cut", fn = function() api.fs.cut() end },
          { name = "7. Paste", fn = function() api.fs.paste() end },
          { name = "8. Duplicate", fn = function() 
            api.fs.copy.node()
            api.fs.paste()
          end },
          { name = "9. --------------------", fn = function() end },
          { name = "0. Rename", fn = function() api.fs.rename() end },
          { name = "a. Delete", fn = function() api.fs.remove() end },
          { name = "b. New File", fn = function() api.fs.create() end },
          { name = "c. New Folder", fn = function() 
            api.fs.create(nil, vim.fn.expand('%:p:h') .. "/NewFolder/")
          end },
          { name = "d. Copy Path", fn = function() api.fs.copy.absolute_path() end },
        }

        -- Display menu
        vim.ui.select(
          context_menu,
          {
            prompt = "NvimTree Actions",
            format_item = function(item) return item.name end,
          },
          function(selected)
            if selected then selected.fn() end
          end
        )
      end, opts("Context Menu"))
      
      -- Allow visual selection and drag
      -- This requires mouse integration
      vim.keymap.set("n", "<LeftDrag>", function()
        -- This is a placeholder for dragging functionality
        -- Complete drag-and-drop would require more complex implementation
        print("Drag and drop functionality is complex in terminal")
      end, opts("Drag Files"))
    end,
  })
end
