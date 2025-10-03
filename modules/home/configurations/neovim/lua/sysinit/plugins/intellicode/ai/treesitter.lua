local M = {}

-- Helper function to get treesitter parser
local function get_parser(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil
  end
  return parser
end

-- Helper function to get the smallest node at cursor position
local function get_node_at_cursor(bufnr, row, col)
  local parser = get_parser(bufnr)
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil
  end

  return tree:root():named_descendant_for_range(row, col, row, col)
end

-- Find the parent node matching any of the given types
local function find_parent_node(node, node_types)
  if not node then
    return nil
  end

  local current = node
  while current do
    if vim.tbl_contains(node_types, current:type()) then
      return current
    end
    current = current:parent()
  end
  return nil
end

-- Get the text content of a node
local function get_node_text(node, bufnr)
  if not node then
    return nil
  end
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return nil
  end
  return text
end

-- Get the current function context
function M.get_current_function(state)
  local node = get_node_at_cursor(state.buf, state.line - 1, state.col)
  if not node then
    return ""
  end

  -- Common function node types across languages
  local function_types = {
    "function_definition", -- Python, Lua
    "function_declaration", -- C, C++, JavaScript, Go
    "method_definition", -- JavaScript, TypeScript, Python
    "method_declaration", -- Java, Go
    "function_item", -- Rust
    "arrow_function", -- JavaScript, TypeScript
    "function_expression", -- JavaScript
    "lambda", -- Python
    "func_literal", -- Go
  }

  local func_node = find_parent_node(node, function_types)
  if not func_node then
    return ""
  end

  -- Try to get function name
  local name_node = func_node:field("name")[1]
  local func_name = name_node and get_node_text(name_node, state.buf) or "anonymous"

  -- Get the full function text (limited to first few lines for context)
  local func_text = get_node_text(func_node, state.buf) or ""
  local lines = vim.split(func_text, "\n")

  -- If function is too long, just show signature (first 5 lines)
  if #lines > 5 then
    local signature = {}
    for i = 1, math.min(5, #lines) do
      table.insert(signature, lines[i])
    end
    return table.concat(signature, "\n") .. "\n  ..."
  end

  return func_text
end

-- Get the current class/type context
function M.get_current_class(state)
  local node = get_node_at_cursor(state.buf, state.line - 1, state.col)
  if not node then
    return ""
  end

  -- Common class/type node types across languages
  local class_types = {
    "class_definition", -- Python
    "class_declaration", -- JavaScript, TypeScript, Java, C++
    "struct_item", -- Rust
    "type_declaration", -- Go, TypeScript
    "interface_declaration", -- TypeScript, Java, Go
    "impl_item", -- Rust
    "trait_item", -- Rust
  }

  local class_node = find_parent_node(node, class_types)
  if not class_node then
    return ""
  end

  -- Try to get class name
  local name_node = class_node:field("name")[1]
  local class_name = name_node and get_node_text(name_node, state.buf) or "anonymous"

  -- Get the class header (first few lines)
  local class_text = get_node_text(class_node, state.buf) or ""
  local lines = vim.split(class_text, "\n")

  -- Show just the class signature and first few methods/fields
  if #lines > 10 then
    local signature = {}
    for i = 1, math.min(10, #lines) do
      table.insert(signature, lines[i])
    end
    return table.concat(signature, "\n") .. "\n  ..."
  end

  return class_text
end

-- Get current treesitter node information
function M.get_current_node(state)
  local node = get_node_at_cursor(state.buf, state.line - 1, state.col)
  if not node then
    return ""
  end

  local node_type = node:type()
  local node_text = get_node_text(node, state.buf) or ""

  -- Limit text length
  if #node_text > 200 then
    node_text = node_text:sub(1, 200) .. "..."
  end

  return string.format("Node type: %s\n%s", node_type, node_text)
end

-- Get all symbols (functions, classes, etc.) in the buffer
function M.get_all_symbols(state)
  local parser = get_parser(state.buf)
  if not parser then
    return ""
  end

  local tree = parser:parse()[1]
  if not tree then
    return ""
  end

  local symbols = {}
  local root = tree:root()

  -- Symbol node types to look for
  local symbol_types = {
    function_definition = true,
    function_declaration = true,
    method_definition = true,
    method_declaration = true,
    function_item = true,
    class_definition = true,
    class_declaration = true,
    struct_item = true,
    type_declaration = true,
    interface_declaration = true,
    impl_item = true,
    trait_item = true,
  }

  -- Traverse the tree to find symbols
  local function traverse(node)
    if symbol_types[node:type()] then
      local name_node = node:field("name")[1]
      if name_node then
        local name = get_node_text(name_node, state.buf)
        local row = node:start()
        if name then
          table.insert(symbols, string.format("%s:%d - %s", node:type(), row + 1, name))
        end
      end
    end

    for child in node:iter_children() do
      traverse(child)
    end
  end

  traverse(root)

  if #symbols == 0 then
    return "No symbols found"
  end

  return table.concat(symbols, "\n")
end

-- Get imports/requires at the top of the file
function M.get_imports(state)
  local parser = get_parser(state.buf)
  if not parser then
    return ""
  end

  local tree = parser:parse()[1]
  if not tree then
    return ""
  end

  local imports = {}
  local root = tree:root()

  -- Import/require node types across languages
  local import_types = {
    import_statement = true, -- JavaScript, TypeScript
    import_from_statement = true, -- Python
    use_declaration = true, -- Rust
    package_clause = true, -- Go
    import_declaration = true, -- Java, Go
    require_call = true, -- Lua (if supported)
  }

  -- Traverse the tree to find imports
  local function traverse(node, depth)
    -- Only look at top-level and first few levels
    if depth > 3 then
      return
    end

    if import_types[node:type()] then
      local import_text = get_node_text(node, state.buf)
      if import_text then
        table.insert(imports, import_text)
      end
    end

    -- Also catch require() calls in Lua
    if node:type() == "function_call" then
      local func_name = node:field("name")
      if func_name and #func_name > 0 then
        local name_text = get_node_text(func_name[1], state.buf)
        if name_text == "require" then
          local full_text = get_node_text(node, state.buf)
          if full_text then
            table.insert(imports, full_text)
          end
        end
      end
    end

    for child in node:iter_children() do
      traverse(child, depth + 1)
    end
  end

  traverse(root, 0)

  if #imports == 0 then
    return ""
  end

  return table.concat(imports, "\n")
end

return M
