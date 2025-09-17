-- Vectorcode Integration for AI System
local M = {}

-- Check if vectorcode is available
function M.is_available()
  return vim.fn.executable("python3") == 1
    and os.execute("python3 -m vectorcode --help >/dev/null 2>&1") == 0
end

-- Get vectorcode context for a query
function M.get_context(query)
  if not M.is_available() then
    return "Vectorcode not available"
  end

  if not query or query == "" then
    return "No query provided for vectorcode"
  end

  local config_path = vim.fn.expand("~/.config/vectorcode/config.json5")
  local cmd = string.format(
    'python3 -m vectorcode query "%s" --config "%s" --collection vectorcode_index --top-k 3 2>/dev/null',
    query:gsub('"', '\\"'),
    config_path
  )

  local result = vim.fn.system(cmd)

  if vim.v.shell_error == 0 and result and result ~= "" then
    -- Truncate if too long
    if #result > 1000 then
      result = result:sub(1, 997) .. "..."
    end
    return "📚 " .. result
  else
    return "📚 No vectorcode context available"
  end
end

-- Index current project
function M.index_current_project()
  if not M.is_available() then
    vim.notify("Vectorcode not available", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local config_path = vim.fn.expand("~/.config/vectorcode/config.json5")

  local cmd = string.format(
    'cd "%s" && python3 -m vectorcode index . --config "%s" --collection vectorcode_index --recursive --exclude-patterns "*.git/*,*node_modules/*,*.venv/*,*__pycache__/*,*.local/share/goose/*"',
    cwd,
    config_path
  )

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Project indexed successfully", vim.log.levels.INFO)
      else
        vim.notify("Failed to index project", vim.log.levels.ERROR)
      end
    end,
  })
end

-- Query vectorcode
function M.query(query_text, callback)
  if not M.is_available() then
    callback(nil, "Vectorcode not available")
    return
  end

  local config_path = vim.fn.expand("~/.config/vectorcode/config.json5")
  local cmd = string.format(
    'python3 -m vectorcode query "%s" --config "%s" --collection vectorcode_index --top-k 5',
    query_text:gsub('"', '\\"'),
    config_path
  )

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local result = table.concat(data, "\n")
        callback(result, nil)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        callback(nil, table.concat(data, "\n"))
      end
    end,
  })
end

-- Check ChromaDB status
function M.check_chromadb_status()
  local handle = io.popen("curl -s http://localhost:8000/api/v1/version 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result and result ~= ""
  end
  return false
end

-- Initialize vectorcode collections
function M.init_collections()
  if not M.check_chromadb_status() then
    vim.notify("ChromaDB not running", vim.log.levels.WARN)
    return
  end

  local script = string.format([[
python3 -c "
import requests
import json

collections = [
    {'name': 'claude_ai_interactions', 'metadata': {'description': 'Claude AI interactions and context'}},
    {'name': 'goose_sessions', 'metadata': {'description': 'Goose AI session data'}},
    {'name': 'cursor_completions', 'metadata': {'description': 'Cursor AI completion data'}},
    {'name': 'opencode_contexts', 'metadata': {'description': 'OpenCode AI context data'}},
    {'name': 'vectorcode_index', 'metadata': {'description': 'Vectorcode indexed files and documentation'}}
]

base_url = 'http://localhost:8000/api/v1'

for collection in collections:
    try:
        response = requests.post(f'{base_url}/collections', json=collection, timeout=5)
        if response.status_code in [200, 409]:  # 409 means already exists
            print(f'Collection {collection[\"name\"]} ready')
        else:
            print(f'Failed to create collection {collection[\"name\"]}: {response.text}')
    except Exception as e:
        print(f'Error creating collection {collection[\"name\"]}: {e}')
"
]])

  vim.fn.jobstart(script, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Vectorcode collections initialized", vim.log.levels.INFO)
      else
        vim.notify("Failed to initialize vectorcode collections", vim.log.levels.ERROR)
      end
    end,
  })
end

-- Setup commands
function M.setup()
  vim.api.nvim_create_user_command("VectorcodeIndex", function()
    M.index_current_project()
  end, { desc = "Index current project with vectorcode" })

  vim.api.nvim_create_user_command("VectorcodeQuery", function(opts)
    M.query(opts.args, function(result, error)
      if error then
        vim.notify("Vectorcode error: " .. error, vim.log.levels.ERROR)
      else
        vim.notify("Vectorcode result:\n" .. (result or "No results"), vim.log.levels.INFO)
      end
    end)
  end, { nargs = 1, desc = "Query vectorcode for context" })

  vim.api.nvim_create_user_command("VectorcodeStatus", function()
    local chromadb_status = M.check_chromadb_status() and "✅ ChromaDB running"
      or "❌ ChromaDB not running"
    local vectorcode_status = M.is_available() and "✅ Vectorcode available"
      or "❌ Vectorcode not available"
    vim.notify(
      string.format("Vectorcode Status:\n%s\n%s", chromadb_status, vectorcode_status),
      vim.log.levels.INFO
    )
  end, { desc = "Check vectorcode status" })

  vim.api.nvim_create_user_command("VectorcodeInit", function()
    M.init_collections()
  end, { desc = "Initialize vectorcode collections" })
end

return M
