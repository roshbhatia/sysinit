local M = {}

-- Set up tree-sitter language injection for ast-grep YAML files
-- This enables syntax highlighting for code patterns within ast-grep rules
function M.setup()
  -- Create custom queries for ast-grep YAML files
  vim.filetype.add({
    pattern = {
      [".*%.astgrep%.ya?ml"] = "yaml.astgrep",
      [".*/ast%-grep/rules/.*%.ya?ml"] = "yaml.astgrep",
      [".*/sgconfig%.ya?ml"] = "yaml.astgrep",
    },
  })

  -- Set up language injection queries for yaml files
  -- This allows highlighting of code patterns within ast-grep rules
  local queries = [[
    ; Inject language syntax highlighting into ast-grep pattern fields
    ((block_mapping_pair
      key: (flow_node) @_key
      value: (block_node
        (block_scalar) @injection.content))
      (#match? @_key "^(pattern|fix)$")
      (#set! injection.language "typescript")
      (#set! injection.include-children))

    ; Inject Go template syntax for template expressions
    ((block_mapping_pair
      key: (flow_node) @_key
      value: (block_node) @injection.content)
      (#match? @_key "^(pattern|fix)$")
      (#lua-match? @injection.content "{{.*}}")
      (#set! injection.language "gotmpl")
      (#set! injection.include-children))

    ; Highlight metavariables in patterns ($VAR, $$$, etc.)
    ((block_scalar) @variable
      (#match? @variable "\\$[A-Z_]+")
      (#set! "priority" 105))
  ]]

  -- Create or update the injection query file
  local query_path = vim.fn.stdpath("config") .. "/after/queries/yaml/injections.scm"
  local query_dir = vim.fn.fnamemodify(query_path, ":h")

  -- Ensure directory exists
  vim.fn.mkdir(query_dir, "p")

  -- Check if file exists and read it
  local existing_content = ""
  local file = io.open(query_path, "r")
  if file then
    existing_content = file:read("*a")
    file:close()
  end

  -- Only add our queries if they're not already present
  if not existing_content:match("ast%-grep pattern") then
    file = io.open(query_path, "a")
    if file then
      file:write("\n; ast-grep pattern injection\n")
      file:write(queries)
      file:write("\n")
      file:close()
    end
  end

  -- Set up custom highlights for ast-grep metavariables
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "yaml", "yaml.astgrep" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local filename = vim.api.nvim_buf_get_name(buf)

      -- Check if this is an ast-grep related file
      if
        filename:match("astgrep")
        or filename:match("ast%-grep/rules")
        or filename:match("sgconfig")
      then
        -- Set up buffer-local syntax for metavariables
        vim.cmd([[
          syntax match astgrepMetaVar /\$[A-Z_]\+/
          syntax match astgrepMetaVarMulti /\$\$\$/
          syntax match astgrepGoTemplate /{{\s*[^}]\+\s*}}/

          highlight default link astgrepMetaVar Special
          highlight default link astgrepMetaVarMulti Constant
          highlight default link astgrepGoTemplate Function
        ]])

        -- Add helpful keymaps for ast-grep yaml editing
        vim.keymap.set("n", "gd", function()
          -- Jump to metavariable definition/usage
          local word = vim.fn.expand("<cword>")
          if word:match("^%$") then
            vim.cmd("/" .. vim.fn.escape(word, "$"))
          end
        end, { buffer = buf, desc = "Jump to metavariable" })
      end
    end,
  })
end

-- Add completion support for ast-grep YAML files
function M.setup_completion()
  local cmp = require("blink.cmp")
  local astgrep_keywords = {
    "id",
    "language",
    "message",
    "note",
    "severity",
    "rule",
    "pattern",
    "kind",
    "regex",
    "all",
    "any",
    "not",
    "inside",
    "has",
    "follows",
    "precedes",
    "constraints",
    "transform",
    "fix",
    "utils",
    "metavariables",
  }

  local metavariable_patterns = {
    "$NAME",
    "$VAR",
    "$VALUE",
    "$FUNC",
    "$ARGS",
    "$$$",
    "$BODY",
    "$EXPR",
    "$TYPE",
    "$MODULE",
  }

  -- Register custom completion source for ast-grep files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "yaml", "yaml.astgrep" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local filename = vim.api.nvim_buf_get_name(buf)

      if
        filename:match("astgrep")
        or filename:match("ast%-grep/rules")
        or filename:match("sgconfig")
      then
        -- Add snippets for common ast-grep patterns
        vim.b.astgrep_snippets = {
          {
            label = "astgrep-rule",
            insertText = [[
id: ${1:rule-name}
language: ${2:typescript}
message: ${3:Rule message}
rule:
  pattern: ${4:pattern}
]],
          },
          {
            label = "astgrep-metavar",
            insertText = "$${1:NAME}",
          },
        }
      end
    end,
  })
end

return M
