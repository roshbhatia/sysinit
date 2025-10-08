local M = {}
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")
local context = require("sysinit.plugins.intellicode.ai.context")
local history = require("sysinit.plugins.intellicode.ai.history")

function M.create_agent_keymaps(agent)
  local ai_terminals = require("ai-terminals")
  local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]

  return {
    {
      string.format("<leader>%s%s", key_prefix, key_prefix),
      function()
        ai_terminals.toggle(termname)
      end,
      desc = "Toggle",
    },
    {
      string.format("<leader>%sv", key_prefix),
      function()
        local last_prompt = terminal.get_last_prompt(termname)
        if last_prompt and last_prompt ~= "" then
          terminal.ensure_terminal_and_send(termname, last_prompt)
        else
          vim.notify("No previous prompt found for", vim.log.levels.WARN)
        end
      end,
      desc = "Resend previous prompt to",
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
      desc = "Ask",
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
      desc = "Fix diagnostics",
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
      desc = "Comment",
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
      desc = "Send quickfix list to",
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
      desc = "Send location list to",
    },
  }
end

function M.create_history_keymaps(agents)
  local history_keymaps = {}

  for _, agent in ipairs(agents) do
    local key_prefix, termname, label = agent[1], agent[2], agent[3]

    table.insert(history_keymaps, {
      string.format("<leader>%sr", key_prefix),
      function()
        history.create_history_picker(termname)
      end,
      desc = "Browse history",
    })
  end

  return history_keymaps
end

function M.create_shared_keymaps()
  local ai_terminals = require("ai-terminals")

  return {
    {
      "<leader>ad",
      ai_terminals.diff_changes,
      desc = "View diff",
    },
    {
      "<leader>ax",
      ai_terminals.revert_changes,
      desc = "Revert changes",
    },
    {
      "<leader>ar",
      function()
        history.create_history_picker(nil)
      end,
      desc = "Browse all AI terminals history",
    },
  }
end

function M.create_specify_keymaps()
  local specify = require("sysinit.plugins.intellicode.ai.specify")
  
  return {
    -- Spec Kit workflow commands (send to Claude terminal)
    {
      "<leader>ass",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.specify ")
      end,
      desc = "SpecKit: Define requirements",
    },
    {
      "<leader>asc",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.constitution ")
      end,
      desc = "SpecKit: Create constitution",
    },
    {
      "<leader>asl",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.clarify")
      end,
      desc = "SpecKit: Clarify requirements",
    },
    {
      "<leader>asp",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.plan ")
      end,
      desc = "SpecKit: Create implementation plan",
    },
    {
      "<leader>ast",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.tasks")
      end,
      desc = "SpecKit: Generate task list",
    },
    {
      "<leader>asa",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.analyze")
      end,
      desc = "SpecKit: Analyze consistency",
    },
    {
      "<leader>ask",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.checklist ")
      end,
      desc = "SpecKit: Generate checklist",
    },
    {
      "<leader>asi",
      function()
        if not specify.is_specify_project() then
          vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
          return
        end
        terminal.ensure_terminal_and_send("claude", "/speckit.implement")
      end,
      desc = "SpecKit: Execute implementation",
    },
    -- Navigation helpers
    {
      "<leader>asf",
      function()
        local spec_dir = specify.get_current_spec_dir()
        if spec_dir then
          vim.cmd("edit " .. spec_dir .. "/spec.md")
        else
          vim.notify("Not in a spec directory", vim.log.levels.WARN)
        end
      end,
      desc = "SpecKit: Open spec.md",
    },
    {
      "<leader>asP",
      function()
        local spec_dir = specify.get_current_spec_dir()
        if spec_dir then
          vim.cmd("edit " .. spec_dir .. "/plan.md")
        else
          vim.notify("Not in a spec directory", vim.log.levels.WARN)
        end
      end,
      desc = "SpecKit: Open plan.md",
    },
    {
      "<leader>asT",
      function()
        local spec_dir = specify.get_current_spec_dir()
        if spec_dir then
          vim.cmd("edit " .. spec_dir .. "/tasks.md")
        else
          vim.notify("Not in a spec directory", vim.log.levels.WARN)
        end
      end,
      desc = "SpecKit: Open tasks.md",
    },
    {
      "<leader>aso",
      function()
        local repo_root = specify.get_repo_root()
        if repo_root then
          vim.cmd("edit " .. repo_root .. "/.specify/memory/constitution.md")
        else
          vim.notify("Not in a Specify project", vim.log.levels.WARN)
        end
      end,
      desc = "SpecKit: Open constitution",
    },
    {
      "<leader>as<leader>",
      function()
        specify.pick_spec_directory()
      end,
      desc = "SpecKit: Browse features",
    },
  }
end

function M.generate_all_keymaps(agents)
  local all_keymaps = {}

  for _, agent in ipairs(agents) do
    vim.list_extend(all_keymaps, M.create_agent_keymaps(agent))
  end

  vim.list_extend(all_keymaps, M.create_history_keymaps(agents))

  vim.list_extend(all_keymaps, M.create_shared_keymaps())

  vim.list_extend(all_keymaps, M.create_specify_keymaps())

  return all_keymaps
end

return M
