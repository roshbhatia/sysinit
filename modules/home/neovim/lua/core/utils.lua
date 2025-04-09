-- Core utilities for Neovim configuration

local M = {}

-- Safely require a module
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Could not load module: " .. module, vim.log.levels.WARN)
    return nil
  end
  return result
end

-- Check if a file exists
function M.file_exists(file)
  local f = io.open(file, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Get visual selection
function M.get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))
  local text
  if ls < le or (ls == le and cs <= ce) then
    text = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
  else
    text = vim.api.nvim_buf_get_text(0, le - 1, ce - 1, ls - 1, cs, {})
  end
  return table.concat(text, "\n")
end

-- Check if running on macOS
function M.is_mac()
  return vim.fn.has("mac") == 1
end

-- Check if running on Linux
function M.is_linux()
  return vim.fn.has("unix") == 1 and not M.is_mac()
end

-- Check if running on Windows
function M.is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

-- Check if in headless mode
function M.is_headless()
  return vim.fn.has("gui_running") == 0 and vim.fn.has("tty") == 0
end

-- Convert hex color to RGB
function M.hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return {
    r = tonumber("0x" .. hex:sub(1, 2)),
    g = tonumber("0x" .. hex:sub(3, 4)),
    b = tonumber("0x" .. hex:sub(5, 6)),
  }
end

-- Create a notification with timeout
function M.notify(message, level, opts)
  level = level or vim.log.levels.INFO
  opts = opts or {}
  -- Check if nvim-notify is available
  local has_notify, notify = pcall(require, "notify")
  if has_notify then
    notify(message, level, opts)
  else
    vim.notify(message, level)
  end
end

-- Toggle a boolean option
function M.toggle_option(option)
  local value = not vim.api.nvim_get_option_value(option, {})
  vim.api.nvim_set_option_value(option, value, {})
  M.notify(option .. " " .. (value and "enabled" or "disabled"), vim.log.levels.INFO)
end

-- Get the git branch
function M.get_git_branch()
  local branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
  if branch ~= "" then
    return branch
  end
  return nil
end

-- Get project root directory
function M.get_root()
  -- Try to find a git directory
  local git_dir = vim.fn.finddir(".git", ".;")
  if git_dir ~= "" then
    return vim.fn.fnamemodify(git_dir, ":h")
  end
  
  -- Try to find a package.json file
  local package_json = vim.fn.findfile("package.json", ".;")
  if package_json ~= "" then
    return vim.fn.fnamemodify(package_json, ":h")
  end
  
  -- Fallback to current working directory
  return vim.fn.getcwd()
end

-- Check if a command exists
function M.command_exists(cmd)
  if vim.fn.executable(cmd) == 1 then
    return true
  end
  return false
end

-- Prepare clipboard integration for macOS
function M.setup_clipboard()
  if M.is_mac() then
    vim.g.clipboard = {
      name = "macOS-clipboard",
      copy = {
        ["+"] = "pbcopy",
        ["*"] = "pbcopy",
      },
      paste = {
        ["+"] = "pbpaste",
        ["*"] = "pbpaste",
      },
      cache_enabled = 0,
    }
  end
end

-- Return a module
return M