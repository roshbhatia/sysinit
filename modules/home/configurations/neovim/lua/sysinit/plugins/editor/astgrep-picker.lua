-- Interactive ast-grep picker with multi-stage workflow
-- Provides a clean UX for ast-grep searches without memorizing syntax

local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")

-- Cache for last search to enable refinement
local last_search = {
  lang = nil,
  pattern = nil,
  results = nil,
}

-- Execute ast-grep and return formatted results
local function execute_astgrep(lang, pattern, opts)
  opts = opts or {}
  local cmd_parts = { "ast-grep" }

  if lang and lang ~= "any" then
    table.insert(cmd_parts, string.format("-l %s", lang))
  end

  -- Escape single quotes in pattern
  local escaped_pattern = pattern:gsub("'", "'\\''")
  table.insert(cmd_parts, string.format("-p '%s'", escaped_pattern))

  if opts.json then
    table.insert(cmd_parts, "--json=stream")
  end

  table.insert(cmd_parts, "2>&1")

  local cmd = table.concat(cmd_parts, " ")
  local handle = io.popen(cmd)
  if not handle then
    return nil, "ast-grep command failed"
  end

  local output = handle:read("*a")
  local success = handle:close()

  if not success or output == "" or output:match("^error:") then
    return nil, output ~= "" and output or "No matches found"
  end

  return output, nil
end

-- Stage 3: Show results in telescope with live preview
local function show_results_picker(lang, pattern, callback)
  local output, err = execute_astgrep(lang, pattern, {})

  if err then
    vim.notify("ast-grep: " .. err, vim.log.levels.WARN)
    return
  end

  -- Cache results for refinement
  last_search = { lang = lang, pattern = pattern, results = output }

  -- Parse output into lines for picker
  local lines = vim.split(output, "\n")
  local entries = {}
  for i, line in ipairs(lines) do
    if line ~= "" then
      table.insert(entries, { line = line, index = i })
    end
  end

  if #entries == 0 then
    vim.notify("No matches found", vim.log.levels.INFO)
    return
  end

  pickers
    .new({}, {
      prompt_title = string.format("ast-grep: %s | %s", lang or "any", pattern),
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.line,
            ordinal = entry.line,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Match Context",
        define_preview = function(self, entry, status)
          -- Show the full results with the selected line highlighted
          local preview_lines = vim.split(output, "\n")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)

          -- Highlight the selected line
          vim.api.nvim_buf_add_highlight(
            self.state.bufnr,
            -1,
            "TelescopeSelection",
            entry.value.index - 1,
            0,
            -1
          )
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          -- Insert all results into callback
          if callback then
            callback(output)
          end
        end)

        -- Ctrl-a: Copy all results to clipboard
        map("i", "<C-a>", function()
          vim.fn.setreg("+", output)
          vim.notify("Copied all results to clipboard", vim.log.levels.INFO)
        end)

        -- Ctrl-r: Refine search (go back to pattern selection)
        map("i", "<C-r>", function()
          actions.close(prompt_bufnr)
          M.start_picker(callback)
        end)

        -- Ctrl-s: Send to current AI terminal
        map("i", "<C-s>", function()
          actions.close(prompt_bufnr)
          local terminal = require("sysinit.plugins.intellicode.ai.terminal")
          local ai_terminals = require("ai-terminals")

          -- Find current terminal
          local agents = require("sysinit.plugins.intellicode.ai.agents").get_agents()
          for _, agent in ipairs(agents) do
            local termname = agent[2]
            local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)
            if term_info and term_info.visible then
              terminal.ensure_terminal_and_send(termname, output)
              return
            end
          end
          vim.notify("No AI terminal open", vim.log.levels.WARN)
        end)

        return true
      end,
    })
    :find()
end

-- Stage 2: Pattern selection or custom input
local function show_pattern_picker(lang, callback)
  local patterns = examples.get_patterns(lang)

  if #patterns == 0 then
    -- No examples, go straight to custom input
    vim.ui.input({
      prompt = string.format("Enter ast-grep pattern for %s: ", lang),
      default = "",
    }, function(pattern)
      if pattern and pattern ~= "" then
        show_results_picker(lang, pattern, callback)
      end
    end)
    return
  end

  -- Add custom option at the top
  local entries = { { name = "Custom pattern...", pattern = nil } }
  for _, name in ipairs(patterns) do
    table.insert(entries, {
      name = name,
      pattern = examples.examples[lang][name],
    })
  end

  pickers
    .new({}, {
      prompt_title = string.format("Select Pattern (%s)", lang),
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Pattern Preview",
        define_preview = function(self, entry, status)
          if not entry.value.pattern then
            vim.api.nvim_buf_set_lines(
              self.state.bufnr,
              0,
              -1,
              false,
              { "Enter a custom ast-grep pattern", "", "Examples:", "  function $NAME($$$) { $$$ }", "  console.log($$$)" }
            )
          else
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
              "Pattern:",
              "",
              entry.value.pattern,
              "",
              "Command:",
              string.format("ast-grep -l %s -p '%s'", lang, entry.value.pattern),
            })
          end
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            if selection.value.pattern then
              -- Use example pattern
              show_results_picker(lang, selection.value.pattern, callback)
            else
              -- Custom pattern input
              vim.ui.input({
                prompt = string.format("Enter ast-grep pattern for %s: ", lang),
                default = "",
              }, function(pattern)
                if pattern and pattern ~= "" then
                  show_results_picker(lang, pattern, callback)
                end
              end)
            end
          end
        end)

        return true
      end,
    })
    :find()
end

-- Stage 1: Language selection
local function show_language_picker(callback)
  local languages = examples.get_languages()

  -- Add "any" option at the top
  table.insert(languages, 1, "any")

  local entries = {}
  for _, lang in ipairs(languages) do
    table.insert(entries, { name = lang })
  end

  pickers
    .new({}, {
      prompt_title = "Select Language",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Language Info",
        define_preview = function(self, entry, status)
          local lang = entry.value.name
          local patterns = examples.get_patterns(lang)

          local lines = { "Language: " .. lang, "" }

          if lang == "any" then
            table.insert(lines, "Search across all languages")
            table.insert(lines, "")
            table.insert(lines, "You'll enter a custom pattern next")
          elseif #patterns > 0 then
            table.insert(lines, "Available patterns:")
            for _, pattern_name in ipairs(patterns) do
              table.insert(lines, "  • " .. pattern_name)
            end
          else
            table.insert(lines, "No example patterns available")
            table.insert(lines, "You'll enter a custom pattern next")
          end

          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            local lang = selection.value.name
            show_pattern_picker(lang, callback)
          end
        end)

        return true
      end,
    })
    :find()
end

-- Main entry point: Start the interactive picker flow
function M.start_picker(callback)
  show_language_picker(callback)
end

-- Quick search with last parameters
function M.repeat_last_search(callback)
  if not last_search.pattern then
    vim.notify("No previous ast-grep search", vim.log.levels.WARN)
    M.start_picker(callback)
    return
  end

  show_results_picker(last_search.lang, last_search.pattern, callback)
end

-- Export for direct use
function M.search_with_pattern(lang, pattern, callback)
  show_results_picker(lang, pattern, callback)
end

return M
