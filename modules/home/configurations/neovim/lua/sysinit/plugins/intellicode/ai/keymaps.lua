local M = {}
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")
local context = require("sysinit.plugins.intellicode.ai.context")
local history = require("sysinit.plugins.intellicode.ai.history")

local function get_current_terminal()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_termname = vim.b[current_buf].ai_terminal_name
  if current_termname then
    return current_termname
  end

  local ai_terminals = require("ai-terminals")
  local agents = require("sysinit.plugins.intellicode.ai.agents").get_agents()

  for _, agent in ipairs(agents) do
    local termname = agent[2]
    local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)
    if term_info and term_info.visible then
      return termname
    end
  end

  return nil
end

local function check_specify_project()
  local specify = require("sysinit.plugins.intellicode.ai.specify")
  if not specify.is_specify_project() then
    vim.notify("Not in a Specify project (.specify directory not found)", vim.log.levels.WARN)
    return false
  end
  return true
end

local function send_to_current_terminal(command)
  local termname = get_current_terminal()
  if not termname then
    vim.notify(
      "No AI terminal is currently open. Please open a terminal first.",
      vim.log.levels.ERROR
    )
    return
  end
  terminal.ensure_terminal_and_send(termname, command)
end

local function create_mode_context_input(termname, icon, action, normal_default, visual_default)
  return function()
    local mode = vim.fn.mode()
    local default_text = mode:match("[vV]") and visual_default or normal_default
    input.create_input(termname, icon, {
      action = action,
      default = default_text,
      on_confirm = function(text)
        terminal.ensure_terminal_and_send(termname, text)
      end,
    })
  end
end

function M.create_agent_keymaps(agent)
  local ai_terminals = require("ai-terminals")
  local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]

  return {
    {
      string.format("<leader>%s%s", key_prefix, key_prefix),
      function()
        ai_terminals.toggle(termname)
      end,
      desc = string.format("%s: Toggle", label),
    },
    {
      string.format("<leader>%sv", key_prefix),
      function()
        local last_prompt = terminal.get_last_prompt(termname)
        if last_prompt and last_prompt ~= "" then
          terminal.ensure_terminal_and_send(termname, last_prompt)
        else
          vim.notify(string.format("No previous prompt found for %s", label), vim.log.levels.WARN)
        end
      end,
      desc = string.format("%s: Resend previous prompt", label),
    },
    {
      string.format("<leader>%sa", key_prefix),
      create_mode_context_input(termname, icon, "Ask", " @cursor: ", " @selection: "),
      mode = { "n", "v" },
      desc = string.format("%s: Ask", label),
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
      desc = string.format("%s: Fix diagnostics", label),
    },
    {
      string.format("<leader>%sc", key_prefix),
      create_mode_context_input(
        termname,
        icon,
        "Comment",
        " Comment @cursor: ",
        " Comment @selection: "
      ),
      mode = { "n", "v" },
      desc = string.format("%s: Comment", label),
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
      desc = string.format("%s: Send quickfix list", label),
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
      desc = string.format("%s: Send location list", label),
    },
    {
      string.format("<leader>%sr", key_prefix),
      function()
        history.create_history_picker(termname)
      end,
      desc = string.format("%s: Browse history", label),
    },
  }
end

function M.create_shared_keymaps()
  local ai_terminals = require("ai-terminals")

  return {
    {
      "<leader>ad",
      ai_terminals.diff_changes,
      desc = "AI: View diff",
    },
    {
      "<leader>ax",
      ai_terminals.revert_changes,
      desc = "AI: Revert changes",
    },
    {
      "<leader>ar",
      function()
        history.create_history_picker(nil)
      end,
      desc = "AI: Browse all history",
    },
  }
end

local function create_speckit_keymap(key, command, description)
  return {
    key,
    function()
      if not check_specify_project() then
        return
      end
      send_to_current_terminal(command)
    end,
    desc = "SpecKit: " .. description,
  }
end

local function create_speckit_nav_keymap(key, file_getter, description)
  return {
    key,
    function()
      local file_path = file_getter()
      if file_path then
        vim.cmd("edit " .. file_path)
      else
        vim.notify("Not in a spec directory", vim.log.levels.WARN)
      end
    end,
    desc = "SpecKit: " .. description,
  }
end

function M.create_specify_keymaps()
  local specify = require("sysinit.plugins.intellicode.ai.specify")

  local keymaps = {
    {
      "<leader>ass",
      function()
        Snacks.terminal.open("specify init --here", {
          win = {
            title = " Specify Init ",
            title_pos = "center",
            width = 0.9,
            height = 0.9,
          },
        })
      end,
      desc = "SpecKit: Initialize project in current directory",
    },
    create_speckit_keymap("<leader>asc", "/speckit.constitution ", "Create constitution"),
    create_speckit_keymap("<leader>asr", "/speckit.specify ", "Define requirements"),
    create_speckit_keymap("<leader>asl", "/speckit.clarify", "Clarify requirements"),
    create_speckit_keymap("<leader>asp", "/speckit.plan ", "Create implementation plan"),
    create_speckit_keymap("<leader>ast", "/speckit.tasks", "Generate task list"),
    create_speckit_keymap("<leader>asa", "/speckit.analyze", "Analyze consistency"),
    create_speckit_keymap("<leader>ask", "/speckit.checklist ", "Generate checklist"),
    create_speckit_keymap("<leader>asi", "/speckit.implement", "Execute implementation"),

    create_speckit_nav_keymap("<leader>asf", function()
      local spec_dir = specify.get_current_spec_dir()
      return spec_dir and spec_dir .. "/spec.md"
    end, "Open spec.md"),

    create_speckit_nav_keymap("<leader>asP", function()
      local spec_dir = specify.get_current_spec_dir()
      return spec_dir and spec_dir .. "/plan.md"
    end, "Open plan.md"),

    create_speckit_nav_keymap("<leader>asT", function()
      local spec_dir = specify.get_current_spec_dir()
      return spec_dir and spec_dir .. "/tasks.md"
    end, "Open tasks.md"),

    create_speckit_nav_keymap("<leader>aso", function()
      local repo_root = specify.get_repo_root()
      return repo_root and repo_root .. "/.specify/memory/constitution.md"
    end, "Open constitution"),

    {
      "<leader>as<leader>",
      function()
        specify.pick_spec_directory()
      end,
      desc = "SpecKit: Browse features",
    },
  }

  return keymaps
end

function M.generate_all_keymaps(agents)
  local all_keymaps = {}

  for _, agent in ipairs(agents) do
    vim.list_extend(all_keymaps, M.create_agent_keymaps(agent))
  end

  vim.list_extend(all_keymaps, M.create_shared_keymaps())

  vim.list_extend(all_keymaps, M.create_specify_keymaps())

  return all_keymaps
end

return M
