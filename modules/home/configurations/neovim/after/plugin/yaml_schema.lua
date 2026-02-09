vim.api.nvim_create_user_command("YamlSchema", function(opts)
  local ft = vim.bo.filetype

  if ft ~= "yaml" and ft ~= "yml" then
    vim.notify(
      string.format("Current filetype is '%s', not YAML. Set to yaml? (Run :set ft=yaml)", ft),
      vim.log.levels.WARN
    )
    return
  end

  local yaml_schema = require("sysinit.utils.yaml_schema")
  yaml_schema.show_schema_picker(opts.bang)
end, {
  desc = "Select YAML schema (auto-detects K8s). Use ! to force show all schemas.",
  bang = true,
})

local function auto_detect_k8s_schema()
  local bufnr = vim.api.nvim_get_current_buf()
  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""

  if first_line:match("^#%s*yaml%-language%-server:%s*%$schema=") then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
  local is_k8s = false

  for _, line in ipairs(lines) do
    if line:match("^%s*apiVersion:%s*") or line:match("^%s*kind:%s*") then
      is_k8s = true
      break
    end
  end

  if is_k8s then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
        local yaml_schema = require("sysinit.utils.yaml_schema")
        yaml_schema.show_schema_picker(false)
      end
    end, 500)
  end
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.yaml", "*.yml" },
  callback = auto_detect_k8s_schema,
  desc = "Auto-open schema picker for Kubernetes YAML files without schema modeline",
})
