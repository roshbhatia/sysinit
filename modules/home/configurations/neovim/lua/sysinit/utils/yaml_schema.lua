local M = {
  _k8s_cache = nil,
  _cache_time = nil,
}

local K8S_CATALOG_API = "https://api.github.com/repos/datreeio/CRDs-catalog/git/trees/main"
local K8S_CATALOG_BASE = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main"

local function is_kubernetes_yaml()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)

  for _, line in ipairs(lines) do
    if line:match("^%s*apiVersion:%s*") or line:match("^%s*kind:%s*") then
      return true
    end
  end

  return false
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
      table.insert(schemas, {
        name = format_k8s_schema_name(item.path),
        path = item.path,
        url = K8S_CATALOG_BASE .. "/" .. item.path,
        source = "K8s CRD",
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

function M.get_all_schemas()
  local k8s = M.fetch_k8s_schemas()
  local store = M.get_schemastore_schemas()

  local all = {}
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

function M.show_schema_picker(force_all)
  local is_k8s = is_kubernetes_yaml()
  local schemas

  if force_all then
    schemas = M.get_all_schemas()
  elseif is_k8s then
    vim.notify("Detected Kubernetes YAML, loading CRD schemas...", vim.log.levels.INFO)
    schemas = M.fetch_k8s_schemas()
    if vim.tbl_isempty(schemas) then
      vim.notify("No K8s schemas available, falling back to SchemaStore", vim.log.levels.WARN)
      schemas = M.get_schemastore_schemas()
    end
  else
    schemas = M.get_schemastore_schemas()
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
    format = function(item)
      return item.text
    end,
    preview = function(item, ctx)
      return {
        { "Name: " .. item.name, "@text.title" },
        { "Source: " .. item.source, "@text.uri" },
        { "URL: " .. item.url, "@comment" },
        item.description and { "\n" .. item.description, "@text" } or nil,
      }
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
