local M = {}
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")
local context = require("sysinit.plugins.intellicode.ai.context")
local git = require("sysinit.plugins.intellicode.ai.git")
local history = require("sysinit.plugins.intellicode.ai.history")
local rich_diffs = require("sysinit.plugins.intellicode.ai.rich-diffs")

function M.create_agent_keymaps(agent)
  local ai_terminals = require("ai-terminals")
  local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]

  return {
    {
      string.format("<leader>%s%s", key_prefix, key_prefix),
      function()
        ai_terminals.toggle(termname)
      end,
      desc = "Toggle " .. label,
    },
    {
      string.format("<leader>%sv", key_prefix),
      function()
        local last_prompt = terminal.get_last_prompt(termname)
        if last_prompt and last_prompt ~= "" then
          terminal.ensure_terminal_and_send(termname, last_prompt)
        else
          vim.notify("No previous prompt found for " .. label, vim.log.levels.WARN)
        end
      end,
      desc = "Resend previous prompt to " .. label,
    },
    {
      string.format("<leader>%sa", key_prefix),
      function()
        local mode = vim.fn.mode()
        local default_text = mode:match("[vV]") and " @selection: " or " @cursor: "
        input.create_input(termname, icon, {
          action = "Ask",
          default = default_text,
          on_confirm = function(text)
            terminal.ensure_terminal_and_send(termname, text)
          end,
        })
      end,
      mode = { "n", "v" },
      desc = "Ask " .. label,
    },
    {
      string.format("<leader>%sf", key_prefix),
      function()
        input.create_input(termname, icon, {
          action = "Fix diagnostics",
          default = " Fix @diagnostic: ",
          on_confirm = function(text)
            terminal.ensure_terminal_and_send(termname, text)
          end,
        })
      end,
      desc = "Fix diagnostics with " .. label,
    },
    {
      string.format("<leader>%sc", key_prefix),
      function()
        local mode = vim.fn.mode()
        local default_text = mode:match("[vV]") and " Comment @selection: " or " Comment @cursor: "
        input.create_input(termname, icon, {
          action = "Comment",
          default = default_text,
          on_confirm = function(text)
            terminal.ensure_terminal_and_send(termname, text)
          end,
        })
      end,
      mode = { "n", "v" },
      desc = "Comment with " .. label,
    },
    {
      string.format("<leader>%sq", key_prefix),
      function()
        input.create_input(termname, icon, {
          action = "Analyze quickfix list",
          default = " Analyze @qflist: ",
          on_confirm = function(text)
            terminal.ensure_terminal_and_send(termname, text)
          end,
        })
      end,
      desc = "Send quickfix list to " .. label,
    },
    {
      string.format("<leader>%sl", key_prefix),
      function()
        input.create_input(termname, icon, {
          action = "Analyze location list",
          default = " Analyze @loclist: ",
          on_confirm = function(text)
            terminal.ensure_terminal_and_send(termname, text)
          end,
        })
      end,
      desc = "Send location list to " .. label,
    },
    {
      string.format("<leader>%sp", key_prefix),
      function()
        local state = context.current_position()
        local result = git.populate_qflist_with_diff(state)
        if result ~= "Quickfix list populated with diff changes" then
          vim.notify(result, vim.log.levels.WARN)
        else
          vim.notify(result, vim.log.levels.INFO)
        end
      end,
      desc = "Populate quickfix with diff for " .. label,
    },
    {
      string.format("<leader>%sr", key_prefix),
      function()
        local state = context.current_position()
        local filepath = vim.api.nvim_buf_get_name(state.buf)
        if filepath == "" then
          vim.notify("No file path available", vim.log.levels.WARN)
          return
        end
        rich_diffs.show_rich_diff(filepath, termname, icon)
      end,
      desc = "Rich diff analysis with " .. label,
    },
    {
      string.format("<leader>%sR", key_prefix),
      function()
        rich_diffs.show_staged_diff(termname, icon)
      end,
      desc = "Rich staged diff analysis with " .. label,
    },
    {
      string.format("<leader>%sW", key_prefix),
      function()
        rich_diffs.show_working_diff(termname, icon)
      end,
      desc = "Rich working diff analysis with " .. label,
    },
    {
      string.format("<leader>%sm", key_prefix),
      function()
        local state = context.current_position()
        local filepath = vim.api.nvim_buf_get_name(state.buf)
        if filepath == "" then
          vim.notify("No file path available", vim.log.levels.WARN)
          return
        end
        local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
        local output = vim.fn.system(cmd)
        if output == "" then
          vim.notify("No git diff available for " .. filepath, vim.log.levels.WARN)
          return
        end
        local diff_data = rich_diffs.parse_git_diff(output)
        if diff_data then
          rich_diffs.generate_commit_message(diff_data, termname, icon)
        end
      end,
      desc = "Generate commit message with " .. label,
    },
  }
end

function M.create_history_keymaps(agents)
  local history_keymaps = {}

  for _, agent in ipairs(agents) do
    local key_prefix, termname, label = agent[1], agent[2], agent[3]

    table.insert(history_keymaps, {
      string.format("<leader>%sh", key_prefix),
      function()
        history.create_history_picker(termname)
      end,
      desc = "Browse " .. label .. " history",
    })

    table.insert(history_keymaps, {
      string.format("<leader>%sH", key_prefix),
      function()
        history.create_history_picker(nil)
      end,
      desc = "Browse all AI terminals history",
    })
  end

  return history_keymaps
end

function M.generate_all_keymaps(agents)
  local all_keymaps = {}

  -- Generate agent-specific keymaps
  for _, agent in ipairs(agents) do
    vim.list_extend(all_keymaps, M.create_agent_keymaps(agent))
  end

  -- Add history keymaps
  vim.list_extend(all_keymaps, M.create_history_keymaps(agents))

  return all_keymaps
end

return M
