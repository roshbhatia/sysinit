local M = {}

M.plugins = {
  {
    "nvzone/volt",
    lazy = true,
  },
  {
    "nvzone/menu",
    lazy = true,
    event = "VeryLazy",
    dependencies = { "nvzone/volt" },
    config = function()
      -- Override default menu
      package.loaded["menus.default"] = {
        {
          name = "Format Buffer",
          cmd = function()
            local ok, conform = pcall(require, "conform")

            if ok then
              conform.format({ lsp_fallback = true })
            else
              vim.lsp.buf.format()
            end
          end,
        },
        {
          name = "Code Actions",
          cmd = vim.lsp.buf.code_action,
          rtxt = "<leader>ca",
        },
        {
          name = "Lsp Actions",
          hl = "Exblue",
          items = "lsp",
        },
        { name = "separator" },
        {
          name = "Copy Content",
          cmd = "%y+",
          rtxt = "<C-c>",
        },
        {
          name = "Delete Content",
          cmd = "%d",
          rtxt = "dc",
        },
      }

      -- Override LSP menu
      package.loaded["menus.lsp"] = {
        {
          name = "Goto Definition",
          cmd = vim.lsp.buf.definition,
        },

        {
          name = "Goto Declaration",
          cmd = vim.lsp.buf.declaration,
        },

        {
          name = "Goto Implementation",
          cmd = vim.lsp.buf.implementation,
        },

        { name = "separator" },

        {
          name = "Show signature help",
          cmd = vim.lsp.buf.signature_help,
        },

        {
          name = "Add workspace folder",
          cmd = vim.lsp.buf.add_workspace_folder,
        },

        {
          name = "Remove workspace folder",
          cmd = vim.lsp.buf.remove_workspace_folder,
        },

        {
          name = "Show References",
          cmd = vim.lsp.buf.references,
        },
        { name = "separator" },
        {
          name = "Format Buffer",
          cmd = function()
            local ok, conform = pcall(require, "conform")

            if ok then
              conform.format({ lsp_fallback = true })
            else
              vim.lsp.buf.format()
            end
          end,
        },
        {
          name = "Code Actions",
          cmd = vim.lsp.buf.code_action,
        },
      }

      -- Override gitsigns menu
      package.loaded["menus.gitsigns"] = {
        {
          name = "Stage Hunk",
          cmd = "Gitsigns stage_hunk",
        },
        {
          name = "Reset Hunk",
          cmd = "Gitsigns reset_hunk",
        },

        {
          name = "Stage Buffer",
          cmd = "Gitsigns stage_buffer",
        },
        {
          name = "Undo Stage Hunk",
          cmd = "Gitsigns undo_stage_hunk",
        },
        {
          name = "Reset Buffer",
          cmd = "Gitsigns reset_buffer",
        },
        {
          name = "Preview Hunk",
          cmd = "Gitsigns preview_hunk",
        },

        { name = "separator" },

        {
          name = "Blame Line",
          cmd = 'lua require"gitsigns".blame_line{full=true}',
        },
        {
          name = "Toggle Current Line Blame",
          cmd = "Gitsigns toggle_current_line_blame",
        },

        { name = "separator" },

        {
          name = "Diff This",
          cmd = "Gitsigns diffthis",
        },
        {
          name = "Diff Last Commit",
          cmd = 'lua require"gitsigns".diffthis("~")',
        },
        {
          name = "Toggle Deleted",
          cmd = "Gitsigns toggle_deleted",
        },
      }

      -- Override neo-tree menu
      local manager = require("neo-tree.sources.manager")
      local cc = require("neo-tree.sources.common.commands")

      local function get_state()
        local state = manager.get_state_for_window()
        assert(state)
        state.config = state.config or {}
        return state
      end

      local function call(what)
        return vim.schedule_wrap(function()
          local state = get_state()
          local cb = require("neo-tree.sources." .. state.name .. ".commands")[what] or cc[what]
          cb(state)
        end)
      end

      local function copy_path(how)
        return function()
          local node = get_state().tree:get_node()
          if node.type == "message" then
            return
          end
          vim.fn.setreg('"', vim.fn.fnamemodify(node.path, how))
          vim.fn.setreg("+", vim.fn.fnamemodify(node.path, how))
        end
      end

      package.loaded["menus.neo-tree"] = {
        { name = "Open in window", cmd = call("open") },
        { name = "Open in vertical split", cmd = call("open_vsplit") },
        { name = "Open in horizontal split", cmd = call("open_split") },
        { name = "separator" },
        { name = "New file", cmd = call("add") },
        { name = "New folder", cmd = call("add_directory") },
        { name = "Delete", hl = "ExRed", cmd = call("Delete") },
        { name = "File details", cmd = call("show_file_details") },
        { name = "Rename", cmd = call("rename") },
        { name = "Rename basename", cmd = call("rename") },
        { name = "Copy", cmd = call("copy_to_clipboard") },
        { name = "Cut", cmd = call("cut_to_clipboard") },
        { name = "Paste", cmd = call("paste_from_clipboard") },
        { name = "separator" },
        { name = "Toggle hidden", cmd = call("toggle_hidden") },
        { name = "Refresh", cmd = call("refresh") },
        {
          name = "Sort by...",
          items = {
            { name = "Sort the tree by created date.", cmd = call("order_by_created") },
            { name = "Sort by diagnostic severity.", cmd = call("order_by_diagnostics") },
            { name = "Sort by git status.", cmd = call("order_by_git_status") },
            { name = "Sort by last modified date.", cmd = call("order_by_modified") },
            { name = "Sort by name (default sort).", cmd = call("order_by_name") },
            { name = "Sort by size.", cmd = call("order_by_size") },
            { name = "Sort by type.", cmd = call("order_by_type") },
          },
        },
        { name = "Fuzzy finder", cmd = call("fuzzy_finder") },
        { name = "Fuzzy finder directory", cmd = call("fuzzy_finder_directory") },
        { name = "Fuzzy sorter", cmd = call("fuzzy_sorter") },
        { name = "separator" },
        { name = "Copy absolute path", cmd = copy_path(":p") },
        { name = "Copy relative path", cmd = copy_path(":~:.") },
      }

      vim.keymap.set("n", "<C-t>", function()
        require("menu").open("default")
      end, { noremap = true, silent = true })

      vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
        require("menu.utils").delete_old_menus()

        vim.cmd.exec('"normal! \\<RightMouse>"')

        -- clicked buf
        local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
        local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

        require("menu").open(options, { mouse = true })
      end, { noremap = true, silent = true })
    end,
  },
}

return M
