local M = {}

-- Enhanced ast-grep pattern picker with examples and preview
local function astgrep_pattern_picker()
  local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  -- Flatten examples into a list
  local items = {}
  for lang, patterns in pairs(examples.examples) do
    for name, pattern in pairs(patterns) do
      table.insert(items, {
        lang = lang,
        name = name,
        pattern = pattern,
        display = string.format("[%s] %s", lang, name),
      })
    end
  end

  pickers
    .new({}, {
      prompt_title = "AST-grep Patterns",
      finder = finders.new_table({
        results = items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display .. " " .. entry.pattern,
            lang = entry.lang,
            name = entry.name,
            pattern = entry.pattern,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Pattern Preview",
        define_preview = function(self, entry, status)
          local lines = {
            "Language: " .. entry.lang,
            "Name: " .. entry.name,
            "",
            "Pattern:",
            entry.pattern,
            "",
            "Example Usage:",
            string.format("ast-grep -l %s -p '%s'", entry.lang, entry.pattern),
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Run ast-grep with the selected pattern
            vim.cmd("Telescope ast_grep")
            -- Pre-fill the pattern in the prompt
            vim.defer_fn(function()
              local prompt = vim.api.nvim_get_current_line()
              vim.api.nvim_set_current_line(selection.pattern)
            end, 100)
          end
        end)

        -- Add keymap to copy pattern to ai-terminals
        map("i", "<C-a>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            -- Get the AI terminal input
            local ai_terminals = require("ai-terminals")
            local placeholder = string.format("@astgrep-lang:%s:%s", selection.lang, selection.pattern)
            vim.notify(
              string.format("Pattern copied: %s\nUse %s in AI terminal", selection.pattern, placeholder),
              vim.log.levels.INFO
            )
            -- Copy to clipboard
            vim.fn.setreg("+", placeholder)
          end
        end)

        return true
      end,
    })
    :find()
end

M.plugins = {
  {
    "0xstepit/ast-grep.nvim",
    cmd = { "AstGrep", "AstGrepSearch", "AstGrepReplace" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("ast-grep").setup({
        command = "ast-grep",

        file_patterns = {
          "*.ts",
          "*.tsx",
          "*.js",
          "*.jsx",
          "*.go",
          "*.py",
          "*.lua",
          "*.nix",
          "*.rs",
          "*.c",
          "*.cpp",
          "*.java",
        },

        search_opts = {
          case_sensitive = false,
          follow_symlinks = true,
          hidden = false,
        },

        telescope = {
          enabled = true,
          theme = "ivy",
        },
      })

      -- Set up tree-sitter integration for ast-grep YAML files
      local ts_setup = require("sysinit.plugins.editor.astgrep-treesitter")
      ts_setup.setup()
      ts_setup.setup_completion()
    end,
    keys = {
      {
        "<leader>fS",
        function()
          require("ast-grep").search_in_files()
        end,
        desc = "Find structural pattern in files",
      },
      {
        "<leader>fR",
        function()
          require("ast-grep").replace()
        end,
        desc = "Replace structural pattern (AST)",
        mode = { "n", "v" },
      },
      {
        "<leader>fP",
        astgrep_pattern_picker,
        desc = "Pick ast-grep pattern from examples",
      },
    },
  },
}

return M
