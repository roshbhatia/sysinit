local neoconf = require("neoconf")

if not neoconf.get("lsp_ai") then
  return { filetypes = {} }
end

local function list_ollama_models()
  if vim.fn.executable("ollama") ~= 1 then
    return {}
  end
  local lines = vim.fn.systemlist({ "ollama", "ls" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local names = {}
  for _, line in ipairs(lines) do
    local name = line:match("^(%S+)")
    if name and name ~= "NAME" then
      table.insert(names, name)
    end
  end
  return names
end

local function detect_models()
  local models = {}

  if vim.env.ANTHROPIC_API_KEY and vim.env.ANTHROPIC_API_KEY ~= "" then
    models["claude"] = {
      type = "anthropic",
      model = "claude-sonnet-4-6",
      api_key_env_var = "ANTHROPIC_API_KEY",
    }
  end

  if vim.env.OPENROUTER_API_KEY and vim.env.OPENROUTER_API_KEY ~= "" then
    models["openrouter"] = {
      type = "openai_compatible",
      model = "deepseek/deepseek-v3.2",
      api_key_env_var = "OPENROUTER_API_KEY",
      base_url = "https://openrouter.ai/api/v1/chat/completions",
    }
  end

  if vim.env.OPENAI_API_KEY and vim.env.OPENAI_API_KEY ~= "" then
    models["openai"] = {
      type = "openai",
      model = "gpt-4o",
      api_key_env_var = "OPENAI_API_KEY",
    }
  end

  if vim.env.GEMINI_API_KEY and vim.env.GEMINI_API_KEY ~= "" then
    models["gemini"] = {
      type = "gemini",
      model = "gemini-2.0-flash",
      api_key_env_var = "GEMINI_API_KEY",
    }
  end

  for _, name in ipairs(list_ollama_models()) do
    models[name] = { type = "ollama", model = name }
  end

  return models
end

local function resolve_models()
  local nc = neoconf.get("lsp_ai") or {}
  return vim.tbl_deep_extend("force", detect_models(), nc.models or {})
end

local function resolve_active(models)
  local nc = neoconf.get("lsp_ai") or {}
  local active = nc.active_model
    or vim.g.lsp_ai_model
    or vim.env.LSP_AI_MODEL
    or (models["claude"] and "claude")
    or (models["openrouter"] and "openrouter")
    or (models["openai"] and "openai")
    or (models["gemini"] and "gemini")
    or next(models)
    or "llama3.2:3b"

  if not models[active] then
    models[active] = { type = "ollama", model = active }
  end

  vim.g.lsp_ai_model = active
  return active
end

local function build_init_options()
  local models = resolve_models()
  local active = resolve_active(models)

  local opts = {
    memory = { file_store = vim.empty_dict() },
    models = models,
    actions = {
      {
        trigger = "!C",
        action_display_name = "Complete",
        model = active,
        parameters = {
          max_context = 4096,
          max_tokens = 4096,
          system = 'Complete the code at "<CURSOR>". Return only the replacement for "<CURSOR>" in <answer> tags.',
          messages = { { role = "user", content = "{CODE}" } },
        },
        post_process = { extractor = "(?s)<answer>(.*?)</answer>" },
      },
      {
        trigger = "!R",
        action_display_name = "Refactor",
        model = active,
        parameters = {
          max_context = 4096,
          max_tokens = 4096,
          system = "Refactor the provided code for clarity and correctness without changing behavior. Return the result in <answer> tags.",
          messages = { { role = "user", content = "{SELECTED_TEXT}" } },
        },
        post_process = { extractor = "(?s)<answer>(.*?)</answer>" },
      },
      {
        trigger = "!E",
        action_display_name = "Explain",
        model = active,
        parameters = {
          max_context = 4096,
          max_tokens = 1024,
          system = "Explain the provided code clearly and concisely. Wrap your explanation in <answer> tags.",
          messages = { { role = "user", content = "{SELECTED_TEXT}" } },
        },
        post_process = { extractor = "(?s)<answer>(.*?)</answer>" },
      },
      {
        trigger = "!S",
        action_display_name = "Simplify",
        model = active,
        parameters = {
          max_context = 4096,
          max_tokens = 4096,
          system = "Simplify the provided code while preserving behavior. Return the result in <answer> tags.",
          messages = { { role = "user", content = "{SELECTED_TEXT}" } },
        },
        post_process = { extractor = "(?s)<answer>(.*?)</answer>" },
      },
    },
  }

  return vim.fn.json_decode(vim.fn.json_encode(opts))
end

local function build_config()
  return {
    cmd = { "lsp-ai", "--stdio" },
    filetypes = {
      "c",
      "cpp",
      "cs",
      "clojure",
      "cmake",
      "dart",
      "go",
      "haskell",
      "html",
      "java",
      "javascript",
      "lua",
      "markdown",
      "nix",
      "php",
      "python",
      "ruby",
      "rust",
      "sh",
      "swift",
      "toml",
      "typescript",
      "typescriptreact",
      "typst",
    },
    root_markers = { ".git" },
    init_options = build_init_options(),
  }
end

if vim.fn.exists(":LspAiModel") == 0 then
  vim.api.nvim_create_user_command("LspAiModel", function(opts)
    local function apply(key)
      vim.g.lsp_ai_model = key
      vim.lsp.config("lsp_ai", build_config())
      for _, client in ipairs(vim.lsp.get_clients({ name = "lsp_ai" })) do
        client.stop()
      end
      vim.defer_fn(function()
        vim.lsp.enable("lsp_ai")
      end, 100)
      vim.notify(("lsp-ai: model → %s"):format(key))
    end

    if opts.args ~= "" then
      apply(opts.args)
      return
    end

    local models = resolve_models()
    local keys = vim.tbl_keys(models)
    table.sort(keys)

    if #keys == 0 then
      vim.notify("lsp-ai: no models available", vim.log.levels.WARN)
      return
    end

    vim.ui.select(keys, {
      prompt = "lsp-ai model",
      format_item = function(key)
        local m = models[key]
        return ("%s  [%s · %s]"):format(key, m.type, m.model)
      end,
    }, function(choice)
      if choice then
        apply(choice)
      end
    end)
  end, {
    nargs = "?",
    complete = function(arg_lead)
      local keys = vim.tbl_keys(resolve_models())
      if arg_lead == "" then
        return keys
      end
      return vim.tbl_filter(function(k)
        return k:sub(1, #arg_lead) == arg_lead
      end, keys)
    end,
    desc = "Switch lsp-ai active model",
  })
end

if vim.fn.exists(":LspAiConfig") == 0 then
  local global_template = [[{
  "lsp_ai": {
    "active_model": "openrouter",
    "models": {
      "openrouter": {
        "type": "openai_compatible",
        "model": "deepseek/deepseek-v3.2",
        "api_key_env_var": "OPENROUTER_API_KEY",
        "base_url": "https://openrouter.ai/api/v1/chat/completions"
      }
    }
  }
}
]]

  local local_template = [[{
  "lsp_ai": {
    "active_model": "openrouter",
    "models": {}
  }
}
]]

  local function open_config(path, template)
    if not vim.uv.fs_stat(path) then
      local dir = vim.fs.dirname(path)
      vim.fn.mkdir(dir, "p")
      local fd = io.open(path, "w")
      if not fd then
        vim.notify("lsp-ai: failed to create " .. path, vim.log.levels.ERROR)
        return
      end
      fd:write(template)
      fd:close()
    end
    vim.cmd.edit(path)
  end

  vim.api.nvim_create_user_command("LspAiConfig", function(opts)
    local scope = opts.args ~= "" and opts.args or nil

    if not scope then
      vim.ui.select({ "global", "local" }, { prompt = "lsp-ai config" }, function(choice)
        if choice then
          vim.cmd("LspAiConfig " .. choice)
        end
      end)
      return
    end

    if scope == "global" then
      local path = vim.fs.joinpath(vim.fn.stdpath("config"), "neoconf.json")
      open_config(path, global_template)
    elseif scope == "local" then
      local path = vim.fs.joinpath(vim.uv.cwd(), ".sysinit", "neoconf.json")
      open_config(path, local_template)
    else
      vim.notify("lsp-ai: usage: LspAiConfig [global|local]", vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "global", "local" }
    end,
    desc = "Edit lsp-ai global or local config",
  })
end

return build_config()
