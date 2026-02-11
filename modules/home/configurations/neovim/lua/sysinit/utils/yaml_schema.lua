local M = {
  _k8s_cache = nil,
  _cache_time = nil,
}

local K8S_CATALOG_API = "https://api.github.com/repos/datreeio/CRDs-catalog/git/trees/main"
local K8S_CATALOG_BASE = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main"
local CUSTOM_SCHEMA_DIR = vim.fn.stdpath("config") .. "/yaml-schemas"

local function extract_k8s_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 100, false)

  local api_version, kind

  for _, line in ipairs(lines) do
    if not api_version then
      local match = line:match("^%s*apiVersion:%s*(.+)")
      if match then
        api_version = match:gsub("%s+$", ""):gsub('"', ""):gsub("'", "")
      end
    end
    if not kind then
      local match = line:match("^%s*kind:%s*(.+)")
      if match then
        kind = match:gsub("%s+$", ""):gsub('"', ""):gsub("'", "")
      end
    end
    if api_version and kind then
      break
    end
  end

  return api_version, kind
end

local function is_kubernetes_yaml()
  local api_version, kind = extract_k8s_info()
  return api_version ~= nil or kind ~= nil
end

local function format_k8s_schema_name(path)
  local name = path:gsub("%.json$", "")
  name = name:gsub("_", " ")
  name = name:gsub("/", " - ")

  local parts = vim.split(name, " ")
  for i, part in ipairs(parts) do
    parts[i] = part:sub(1, 1):upper() .. part:sub(2)
  end

  return table.concat(parts, " ")
end

function M.fetch_k8s_schemas()
  if M._k8s_cache then
    return M._k8s_cache
  end

  local result = vim.fn.system({
    "curl",
    "-s",
    "-H",
    "Accept: application/vnd.github+json",
    "-H",
    "X-GitHub-Api-Version: 2022-11-28",
    K8S_CATALOG_API .. "?recursive=1",
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to fetch K8s CRD catalog", vim.log.levels.ERROR)
    return {}
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data.tree then
    vim.notify("Failed to parse K8s CRD catalog", vim.log.levels.ERROR)
    return {}
  end

  local schemas = {}
  for _, item in ipairs(data.tree) do
    if item.type == "blob" and item.path:match("%.json$") then
      local path_lower = item.path:lower()
      local group, kind

      -- Extract group and kind from path (e.g. "argoproj.io/application_v1alpha1.json")
      local group_match, kind_match = path_lower:match("([^/]+)/([^_]+)")
      if group_match and kind_match then
        group = group_match
        kind = kind_match
      else
        kind = path_lower:match("([^/]+)%.json$")
      end

      table.insert(schemas, {
        name = format_k8s_schema_name(item.path),
        path = item.path,
        url = K8S_CATALOG_BASE .. "/" .. item.path,
        source = "K8s CRD",
        group = group,
        kind = kind,
      })
    end
  end

  table.sort(schemas, function(a, b)
    return a.name < b.name
  end)

  M._k8s_cache = schemas
  return schemas
end

function M.get_schemastore_schemas()
  local ok, schemastore = pcall(require, "schemastore")
  if not ok then
    return {}
  end

  local schemas = schemastore.yaml.schemas()
  local formatted = {}

  for _, schema in ipairs(schemas) do
    table.insert(formatted, {
      name = schema.name,
      url = schema.url,
      description = schema.description,
      source = "SchemaStore",
    })
  end

  return formatted
end

function M.get_custom_schemas()
  vim.fn.mkdir(CUSTOM_SCHEMA_DIR, "p")

  local schemas = {}
  local files = vim.fn.glob(CUSTOM_SCHEMA_DIR .. "/*.json", false, true)

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local metadata_file = file:gsub("%.json$", ".meta")
    local group, kind

    -- Try to load metadata if exists
    if vim.fn.filereadable(metadata_file) == 1 then
      local meta_lines = vim.fn.readfile(metadata_file)
      for _, line in ipairs(meta_lines) do
        if line:match("^group=") then
          group = line:match("^group=(.*)$")
        elseif line:match("^kind=") then
          kind = line:match("^kind=(.*)$")
        end
      end
    end

    table.insert(schemas, {
      name = name,
      url = "file://" .. file,
      source = "Custom",
      group = group,
      kind = kind,
    })
  end

  return schemas
end

function M.cache_schema_from_url()
  vim.ui.input({
    prompt = "Schema URL: ",
    default = "https://",
  }, function(url)
    if not url or url == "" then
      return
    end

    vim.ui.input({
      prompt = "Schema name (e.g. argocd-application): ",
    }, function(name)
      if not name or name == "" then
        vim.notify("Schema name required", vim.log.levels.ERROR)
        return
      end

      M._download_and_save_schema(url, name)
    end)
  end)
end

function M.cache_schema_from_clipboard()
  local url = vim.fn.getreg("+")
  if not url or url == "" then
    vim.notify("Clipboard is empty", vim.log.levels.ERROR)
    return
  end

  url = url:match("^%s*(.-)%s*$")

  if not url:match("^https?://") and not url:match("^file://") then
    vim.notify("Clipboard does not contain a valid URL", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({
    prompt = "Schema name (e.g. argocd-application): ",
  }, function(name)
    if not name or name == "" then
      vim.notify("Schema name required", vim.log.levels.ERROR)
      return
    end

    M._download_and_save_schema(url, name)
  end)
end

function M.cache_schema_from_file()
  vim.ui.input({
    prompt = "Schema file path: ",
    default = vim.fn.expand("%:p:h") .. "/",
    completion = "file",
  }, function(filepath)
    if not filepath or filepath == "" then
      return
    end

    filepath = vim.fn.expand(filepath)

    if vim.fn.filereadable(filepath) ~= 1 then
      vim.notify("File not readable: " .. filepath, vim.log.levels.ERROR)
      return
    end

    vim.ui.input({
      prompt = "Schema name (e.g. argocd-application): ",
      default = vim.fn.fnamemodify(filepath, ":t:r"),
    }, function(name)
      if not name or name == "" then
        vim.notify("Schema name required", vim.log.levels.ERROR)
        return
      end

      name = name:gsub("[^%w%-_]", "-")
      local dest = CUSTOM_SCHEMA_DIR .. "/" .. name .. ".json"

      vim.fn.mkdir(CUSTOM_SCHEMA_DIR, "p")

      local ok = vim.loop.fs_copyfile(filepath, dest)
      if not ok then
        vim.notify("Failed to copy schema file", vim.log.levels.ERROR)
        return
      end

      -- Try to extract apiVersion and kind from current buffer for metadata
      local api_version, kind = extract_k8s_info()
      if api_version and kind then
        local group = api_version:match("^([^/]+)/") or ""
        local metadata_file = dest:gsub("%.json$", ".meta")
        vim.fn.writefile({
          "group=" .. group,
          "kind=" .. kind:lower(),
        }, metadata_file)
      end

      vim.notify(string.format("Cached schema '%s' to %s", name, dest), vim.log.levels.INFO)

      M.insert_schema_modeline("file://" .. dest)
    end)
  end)
end

function M._download_and_save_schema(url, name)
  name = name:gsub("[^%w%-_]", "-")
  local filepath = CUSTOM_SCHEMA_DIR .. "/" .. name .. ".json"

  vim.fn.mkdir(CUSTOM_SCHEMA_DIR, "p")

  vim.notify("Downloading schema...", vim.log.levels.INFO)
  local result = vim.fn.system({
    "curl",
    "-sL",
    "-o",
    filepath,
    url,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to download schema: " .. result, vim.log.levels.ERROR)
    return
  end

  local size = vim.fn.getfsize(filepath)
  if size <= 0 then
    vim.fn.delete(filepath)
    vim.notify("Downloaded file is empty or invalid", vim.log.levels.ERROR)
    return
  end

  -- Try to extract apiVersion and kind from current buffer for metadata
  local api_version, kind = extract_k8s_info()
  if api_version and kind then
    local group = api_version:match("^([^/]+)/") or ""
    local metadata_file = filepath:gsub("%.json$", ".meta")
    vim.fn.writefile({
      "group=" .. group,
      "kind=" .. kind:lower(),
    }, metadata_file)
  end

  vim.notify(string.format("Cached schema '%s' to %s", name, filepath), vim.log.levels.INFO)

  M.insert_schema_modeline("file://" .. filepath)
end

function M.get_all_schemas()
  local custom = M.get_custom_schemas()
  local k8s = M.fetch_k8s_schemas()
  local store = M.get_schemastore_schemas()

  local all = {}
  vim.list_extend(all, custom)
  vim.list_extend(all, store)
  vim.list_extend(all, k8s)

  return all
end

function M.insert_schema_modeline(url)
  local bufnr = vim.api.nvim_get_current_buf()
  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""

  local modeline = "# yaml-language-server: $schema=" .. url

  if first_line:match("^#%s*yaml%-language%-server:%s*%$schema=") then
    vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { modeline })
    vim.notify("Replaced existing schema modeline", vim.log.levels.INFO)
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { modeline })
    vim.notify("Added schema modeline", vim.log.levels.INFO)
  end
end

function M.find_matching_schema(schemas, api_version, kind)
  if not api_version or not kind then
    return nil
  end

  local group = api_version:match("^([^/]+)/") or ""
  local kind_lower = kind:lower()

  -- Try exact match first
  for _, schema in ipairs(schemas) do
    if schema.group and schema.kind then
      if schema.group:lower() == group:lower() and schema.kind:lower() == kind_lower then
        return schema
      end
    end
  end

  -- Try kind-only match
  for _, schema in ipairs(schemas) do
    if schema.kind and schema.kind:lower() == kind_lower then
      return schema
    end
  end

  return nil
end

function M.auto_apply_schema()
  local api_version, kind = extract_k8s_info()
  if not api_version or not kind then
    return false
  end

  -- Check if schema modeline already exists
  local bufnr = vim.api.nvim_get_current_buf()
  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
  if first_line:match("^#%s*yaml%-language%-server:%s*%$schema=") then
    return false
  end

  local all_schemas = M.get_all_schemas()
  local matched = M.find_matching_schema(all_schemas, api_version, kind)

  if matched then
    M.insert_schema_modeline(matched.url)
    vim.notify(string.format("Auto-applied schema: %s", matched.name), vim.log.levels.INFO)
    return true
  end

  return false
end

function M.show_schema_picker(force_all)
  local is_k8s = is_kubernetes_yaml()
  local schemas

  if force_all then
    schemas = M.get_all_schemas()
  elseif is_k8s then
    vim.notify("Detected Kubernetes YAML, loading CRD schemas...", vim.log.levels.INFO)
    local custom = M.get_custom_schemas()
    local k8s = M.fetch_k8s_schemas()
    schemas = {}
    vim.list_extend(schemas, custom)
    vim.list_extend(schemas, k8s)
    if vim.tbl_isempty(schemas) then
      vim.notify("No K8s schemas available, falling back to SchemaStore", vim.log.levels.WARN)
      schemas = M.get_schemastore_schemas()
    end
  else
    local custom = M.get_custom_schemas()
    local store = M.get_schemastore_schemas()
    schemas = {}
    vim.list_extend(schemas, custom)
    vim.list_extend(schemas, store)
  end

  if vim.tbl_isempty(schemas) then
    vim.notify("No schemas available", vim.log.levels.ERROR)
    return
  end

  local items = {}
  for _, schema in ipairs(schemas) do
    table.insert(items, {
      text = string.format("[%s] %s", schema.source, schema.name),
      url = schema.url,
      name = schema.name,
      source = schema.source,
      description = schema.description or "",
    })
  end

  Snacks.picker.pick({
    title = "YAML Schema Selector",
    format = "text",
    preview = function(item, ctx)
      local lines = {
        { "Name: " .. item.name, "@text.title" },
        { "Source: " .. item.source, "@text.uri" },
        { "URL: " .. item.url, "@comment" },
      }
      if item.description and item.description ~= "" then
        table.insert(lines, { "\n" .. item.description, "@text" })
      end
      return lines
    end,
    finder = function()
      return items
    end,
    actions = {
      default = function(item)
        M.insert_schema_modeline(item.url)
      end,
    },
  })
end

return M
