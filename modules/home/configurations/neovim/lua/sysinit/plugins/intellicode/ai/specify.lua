local M = {}

-- Spec Kit slash commands from the README
M.speckit_commands = {
  {
    command = "/speckit.constitution",
    description = "Create project principles and development guidelines",
    category = "Foundation",
  },
  {
    command = "/speckit.specify",
    description = "Define requirements and user stories for what you want to build",
    category = "Specification",
  },
  {
    command = "/speckit.clarify",
    description = "Clarify underspecified areas (recommended before /speckit.plan)",
    category = "Specification",
  },
  {
    command = "/speckit.plan",
    description = "Create technical implementation plans with your chosen tech stack",
    category = "Planning",
  },
  {
    command = "/speckit.tasks",
    description = "Generate actionable task lists for implementation",
    category = "Planning",
  },
  {
    command = "/speckit.analyze",
    description = "Cross-artifact consistency & coverage analysis",
    category = "Quality",
  },
  {
    command = "/speckit.checklist",
    description = "Generate custom quality checklists for validation",
    category = "Quality",
  },
  {
    command = "/speckit.implement",
    description = "Execute all tasks to build the feature according to the plan",
    category = "Implementation",
  },
}

-- Placeholder tokens specific to Specify workflows
M.specify_placeholders = {
  {
    token = "@spec",
    description = "Current specification file (from .specify/specs/*/spec.md)",
  },
  {
    token = "@plan",
    description = "Current implementation plan (from .specify/specs/*/plan.md)",
  },
  {
    token = "@tasks",
    description = "Current task list (from .specify/specs/*/tasks.md)",
  },
  {
    token = "@constitution",
    description = "Project constitution and principles (from .specify/memory/constitution.md)",
  },
  {
    token = "@contracts",
    description = "API contracts and schemas (from .specify/specs/*/contracts/)",
  },
  {
    token = "@research",
    description = "Research documents (from .specify/specs/*/research/)",
  },
}

-- Get the repository root
function M.get_repo_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if not repo_root or repo_root == "" then
    -- Try to find .specify directory going up from current dir
    local current_dir = vim.fn.getcwd()
    while current_dir ~= "/" do
      if vim.fn.isdirectory(current_dir .. "/.specify") == 1 then
        return current_dir
      end
      current_dir = vim.fn.fnamemodify(current_dir, ":h")
    end
    return nil
  end

  return repo_root
end

-- Get the current .specify spec directory if we're in one
function M.get_current_spec_dir()
  local repo_root = M.get_repo_root()
  if not repo_root then
    return nil
  end

  local spec_file = vim.fn.expand("%:p")
  local specs_dir = repo_root .. "/specs"

  -- Check if current file is under specs/
  if spec_file:match(specs_dir .. "/") then
    local spec_dir = spec_file:match("(.*/specs/[^/]+)/")
    return spec_dir
  end

  -- If not in a spec file, try to detect from git branch name
  local handle = io.popen("git branch --show-current 2>/dev/null")
  local branch = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if branch and branch ~= "" and branch:match("^%d%d%d%-") then
    -- Branch looks like a spec branch (e.g., 001-feature-name)
    local potential_dir = specs_dir .. "/" .. branch
    if vim.fn.isdirectory(potential_dir) == 1 then
      return potential_dir
    end
  end

  return nil
end

-- Check if we're in a Specify project
function M.is_specify_project()
  local repo_root = M.get_repo_root()
  if not repo_root then
    return false
  end
  return vim.fn.isdirectory(repo_root .. "/.specify") == 1
end

-- Get all spec directories
function M.get_all_spec_dirs()
  local repo_root = M.get_repo_root()
  if not repo_root then
    return {}
  end

  local specs_dir = repo_root .. "/specs"
  local spec_dirs = {}

  local handle = io.popen("find " .. specs_dir .. " -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null")
  if handle then
    for line in handle:lines() do
      table.insert(spec_dirs, line)
    end
    handle:close()
  end

  return spec_dirs
end

-- Read a file from the current spec directory
function M.read_spec_file(filename)
  local spec_dir = M.get_current_spec_dir()
  if not spec_dir then
    return nil
  end

  local filepath = spec_dir .. "/" .. filename
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()
  return content
end

-- Get constitution file
function M.get_constitution()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  local repo_root = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
  handle:close()

  if not repo_root or repo_root == "" then
    return nil
  end

  local constitution_path = repo_root .. "/.specify/memory/constitution.md"
  local file = io.open(constitution_path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()
  return content
end

-- Apply Specify-specific placeholders
function M.apply_specify_placeholders(input)
  if not input or input == "" then
    return input
  end

  local result = input

  -- @spec placeholder
  if result:find("@spec", 1, true) then
    local spec_content = M.read_spec_file("spec.md")
    if spec_content then
      result = result:gsub("@spec", spec_content)
    end
  end

  -- @plan placeholder
  if result:find("@plan", 1, true) then
    local plan_content = M.read_spec_file("plan.md")
    if plan_content then
      result = result:gsub("@plan", plan_content)
    end
  end

  -- @tasks placeholder
  if result:find("@tasks", 1, true) then
    local tasks_content = M.read_spec_file("tasks.md")
    if tasks_content then
      result = result:gsub("@tasks", tasks_content)
    end
  end

  -- @constitution placeholder
  if result:find("@constitution", 1, true) then
    local constitution_content = M.get_constitution()
    if constitution_content then
      result = result:gsub("@constitution", constitution_content)
    end
  end

  -- @contracts placeholder - list all contract files
  if result:find("@contracts", 1, true) then
    local spec_dir = M.get_current_spec_dir()
    if spec_dir then
      local contracts_dir = spec_dir .. "/contracts"
      local handle = io.popen("find " .. contracts_dir .. " -type f 2>/dev/null")
      if handle then
        local files = handle:read("*all")
        handle:close()
        result = result:gsub("@contracts", files)
      end
    end
  end

  -- @research placeholder - list all research files
  if result:find("@research", 1, true) then
    local spec_dir = M.get_current_spec_dir()
    if spec_dir then
      local research_dir = spec_dir .. "/research"
      local handle = io.popen("find " .. research_dir .. " -type f 2>/dev/null")
      if handle then
        local files = handle:read("*all")
        handle:close()
        result = result:gsub("@research", files)
      end
    end
  end

  return result
end

-- Create a telescope picker for spec directories
function M.pick_spec_directory()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  local spec_dirs = M.get_all_spec_dirs()
  if #spec_dirs == 0 then
    vim.notify("No spec directories found", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local entries = {}
  for _, dir in ipairs(spec_dirs) do
    local name = vim.fn.fnamemodify(dir, ":t")
    table.insert(entries, {
      display = name,
      path = dir,
      spec_file = dir .. "/spec.md",
      plan_file = dir .. "/plan.md",
      tasks_file = dir .. "/tasks.md",
    })
  end

  pickers
    .new({}, {
      prompt_title = "Spec Kit Features",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Open spec.md by default
            vim.cmd("edit " .. selection.value.spec_file)
          end
        end)

        -- Add custom mappings for other files
        map("i", "<C-p>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            vim.cmd("edit " .. selection.value.plan_file)
          end
        end)

        map("i", "<C-t>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            vim.cmd("edit " .. selection.value.tasks_file)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
