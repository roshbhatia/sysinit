-- Parse JSON to ensure file_store is an object, not an array
local init_options_json = [[
{
  "memory": {
    "file_store": {}
  },
  "models": {
    "llama3_2_3b": {
      "type": "ollama",
      "model": "llama3.2:3b"
    }
  },
  "actions": [
    {
      "trigger": "!C",
      "action_display_name": "Complete",
      "model": "llama3_2_3b",
      "parameters": {
        "max_context": 4096,
        "max_tokens": 4096,
        "system": "You are an AI coding assistant. Your task is to complete code snippets. The user's cursor position is marked by \"<CURSOR>\". Follow these steps:\n\n1. Analyze the code context and the cursor position.\n2. Provide your chain of thought reasoning, wrapped in <reasoning> tags.\n3. Determine the appropriate code to complete the current thought.\n4. Replace \"<CURSOR>\" with the necessary code.\n5. Wrap your code solution in <answer> tags.\n\nYour response should always include both the reasoning and the answer.",
        "messages": [
          {
            "role": "user",
            "content": "{CODE}"
          }
        ]
      },
      "post_process": {
        "extractor": "(?s)<answer>(.*?)</answer>"
      }
    },
    {
      "trigger": "!R",
      "action_display_name": "Refactor",
      "model": "llama3_2_3b",
      "parameters": {
        "max_context": 4096,
        "max_tokens": 4096,
        "system": "You are an AI coding assistant specializing in code refactoring. Your task is to analyze the given code snippet and provide a refactored version. Follow these steps:\n\n1. Analyze the code context and structure.\n2. Identify areas for improvement.\n3. Provide your chain of thought reasoning, wrapped in <reasoning> tags.\n4. Rewrite the entire code snippet with your refactoring applied.\n5. Wrap your refactored code solution in <answer> tags.\n\nYour response should always include both the reasoning and the refactored code.",
        "messages": [
          {
            "role": "user",
            "content": "{SELECTED_TEXT}"
          }
        ]
      },
      "post_process": {
        "extractor": "(?s)<answer>(.*?)</answer>"
      }
    },
    {
      "trigger": "!K",
      "action_display_name": "Comment",
      "model": "llama3_2_3b",
      "parameters": {
        "max_context": 4096,
        "max_tokens": 4096,
        "system": "You are an AI coding assistant. Your task is to add high-impact comments to code. Only add comments that explain WHY something is done, not WHAT is being done. Avoid redundant comments that merely restate the code. Follow these steps:\n\n1. Analyze the code for complex logic, non-obvious decisions, or important context.\n2. Provide your reasoning in <reasoning> tags.\n3. Add concise comments only where they provide genuine insight.\n4. Return the code with your comments in <answer> tags.\n\nYour response should always include both the reasoning and the answer.",
        "messages": [
          {
            "role": "user",
            "content": "{SELECTED_TEXT}"
          }
        ]
      },
      "post_process": {
        "extractor": "(?s)<answer>(.*?)</answer>"
      }
    },
    {
      "trigger": "!T",
      "action_display_name": "Write Test",
      "model": "llama3_2_3b",
      "parameters": {
        "max_context": 4096,
        "max_tokens": 4096,
        "system": "You are an AI coding assistant specializing in test writing. Your task is to write tests for the given code. Follow these steps:\n\n1. Analyze the code to understand its functionality and edge cases.\n2. Provide your reasoning in <reasoning> tags.\n3. Write comprehensive tests covering normal cases, edge cases, and error conditions.\n4. Use the appropriate testing framework for the language.\n5. Return the test code in <answer> tags.\n\nYour response should always include both the reasoning and the answer.",
        "messages": [
          {
            "role": "user",
            "content": "{SELECTED_TEXT}"
          }
        ]
      },
      "post_process": {
        "extractor": "(?s)<answer>(.*?)</answer>"
      }
    },
    {
      "trigger": "!V",
      "action_display_name": "Review",
      "model": "llama3_2_3b",
      "parameters": {
        "max_context": 4096,
        "max_tokens": 4096,
        "system": "You are an AI code reviewer. Your task is to review the code and add high-impact inline comments. Only add comments that highlight important issues, potential bugs, performance concerns, or suggest meaningful improvements. Avoid redundant or obvious comments. Follow these steps:\n\n1. Analyze the code for issues, improvements, and best practices.\n2. Provide your reasoning in <reasoning> tags.\n3. Add inline comments directly in the code where issues or suggestions apply.\n4. Return the code with review comments in <answer> tags.\n\nYour response should always include both the reasoning and the answer.",
        "messages": [
          {
            "role": "user",
            "content": "{SELECTED_TEXT}"
          }
        ]
      },
      "post_process": {
        "extractor": "(?s)<answer>(.*?)</answer>"
      }
    }
  ]
}
]]

return {
  cmd = { "lsp-ai", "--stdio" },
  filetypes = {
    "asciidoc",
    "c",
    "cpp",
    "cs",
    "gitcommit",
    "go",
    "html",
    "java",
    "javascript",
    "lua",
    "markdown",
    "nix",
    "python",
    "ruby",
    "rust",
    "swift",
    "toml",
    "typescript",
    "typescriptreact",
    "haskell",
    "cmake",
    "typst",
    "php",
    "dart",
    "clojure",
    "sh",
  },
  root_markers = { ".git" },
  init_options = vim.fn.json_decode(init_options_json),
}
