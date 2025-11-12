-- Simple validation helper for gotmpl injections
-- Usage inside Neovim:
-- :luafile % (when editing this file) or require('sysinit.dev.ts_validate_gotmpl').run()
-- Opens current buffer, iterates lines, applies heuristic regexes mirroring injections.scm
-- Prints a summary table of line -> detected language.

local M = {}

local patterns = {
  json_open_obj = "^[\t ]*{",
  json_open_arr = "^[\t ]*%[",
  json_key = '^[\t ]*"[^"]+"[ \t]*:',
  json_close = "^[\t ]*[}%]],?$",
  json_primitive = "^[\t ]*(true|false|null|[0-9][0-9]*),?$",
  yaml_key = "^[\t ]*[A-Za-z0-9_-]+:[ ]",
  yaml_struct = "^(---|apiVersion:|kind:|metadata:|spec:|template:)",
  override_yaml = "{{/%* yaml %*/}}",
  override_json = "{{/%* json %*/}}",
  override_raw = "{{/%* raw %*/}}",
  k8s_fallback = "(apiVersion:|kind:|metadata:|spec:|labels:|annotations:)",
}

local function classify(line)
  for name, pat in pairs({
    override_raw = patterns.override_raw,
    override_yaml = patterns.override_yaml,
    override_json = patterns.override_json,
  }) do
    if line:match(pat) then
      if name == "override_raw" then
        return "gotmpl", name
      end
      if name == "override_yaml" then
        return "yaml", name
      end
      if name == "override_json" then
        return "json", name
      end
    end
  end
  if
    line:match(patterns.json_open_obj)
    or line:match(patterns.json_open_arr)
    or line:match(patterns.json_key)
    or line:match(patterns.json_close)
    or line:match(patterns.json_primitive)
  then
    return "json", "json_heuristic"
  end
  if line:match(patterns.yaml_key) or line:match(patterns.yaml_struct) then
    return "yaml", "yaml_struct_or_key"
  end
  if
    line:match(patterns.k8s_fallback)
    and not (
      line:match("{{")
      or line:match("}}")
      or line:match(patterns.json_open_obj)
      or line:match(patterns.json_open_arr)
      or line:match(patterns.json_key)
    )
  then
    return "yaml", "k8s_fallback"
  end
  return "gotmpl", "none"
end

function M.run(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local results = {}
  for i, l in ipairs(lines) do
    local lang, why = classify(l)
    table.insert(results, string.format("%4d | %-6s | %s", i, lang, why))
  end
  vim.notify("gotmpl injection heuristic summary:\n" .. table.concat(results, "\n"))
end

return M
