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
    }
  ]
}
]]

return {
  cmd = { "lsp-ai", "--stdio" },
  -- Always return cwd as root so it activates everywhere
  root_dir = function(_, on_dir)
    on_dir(vim.uv.cwd())
  end,
  init_options = vim.fn.json_decode(init_options_json),
}
