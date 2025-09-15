{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  lsp = import ../shared/lsp.nix;
  agents = import ../shared/agents.nix;
  opencodeEnabled = values.llm.opencode.enabled or false;
in
lib.mkIf opencodeEnabled {
  xdg.configFile = {
    "opencode/opencode.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        share = "disabled";
        theme = "system";
        autoupdate = true;
        mcp = {
          fetch = {
            type = "local";
            enabled = true;
            command = [ mcpServers.servers.fetch.command ] ++ mcpServers.servers.fetch.args;
          };
          memory = {
            type = "local";
            enabled = true;
            environment = mcpServers.servers.memory.env;
            command = [ mcpServers.servers.memory.command ] ++ mcpServers.servers.memory.args;
          };
          context7 = {
            type = "local";
            enabled = true;
            command = [ mcpServers.servers.context7.command ] ++ mcpServers.servers.context7.args;
          };
          neovim = {
            type = "local";
            enabled = true;
            command = [ mcpServers.servers.neovim.command ] ++ mcpServers.servers.neovim.args;
          };
        };
        lsp = builtins.mapAttrs (_name: lsp: {
          command = (lsp.command or [ ]) ++ (lsp.args or [ ]);
          extensions = lsp.extensions or [ ];
        }) lsp.lsp;
        agent = {
          ai-engineer = {
            description = "Builds LLM applications, RAG systems, and prompt pipelines. Implements vector search, agent orchestration, and AI API integrations. Use PROACTIVELY for LLM features, chatbots, or AI-powered applications.";
            mode = "subagent";
            prompt = "{file:./prompts/ai-engineer.nix}";
          };
          backend-architect = {
            description = "Design RESTful APIs, microservice boundaries, and database schemas. Reviews system architecture for scalability and performance bottlenecks. Use PROACTIVELY when creating new backend services or APIs.";
            mode = "subagent";
            prompt = "{file:./prompts/backend-architect.nix}";
          };
          frontend-developer = {
            description = "Build Next.js applications with React components, shadcn/ui, and Tailwind CSS. Expert in SSR/SSG, app router, and modern frontend patterns. Use PROACTIVELY for Next.js development, UI component creation, or frontend architecture.";
            mode = "subagent";
            prompt = "{file:./prompts/frontend-developer.nix}";
          };
          typescript-expert = {
            description = "Write type-safe TypeScript with advanced type system features, generics, and utility types. Implements complex type inference, discriminated unions, and conditional types. Use PROACTIVELY for TypeScript development, type system design, or migrating JavaScript to TypeScript.";
            mode = "subagent";
            prompt = "{file:./prompts/typescript-expert.nix}";
          };
        };
        keybinds = {
          leader = "ctrl+,";
        };
      };
      force = true;
    };
  }
  // builtins.listToAttrs (
    map (agent: {
      name = "opencode/prompts/${agent.name}.nix";
      value = {
        source = toString ../. + "/prompts/${agent.name}.nix";
      };
    }) agents
  );
}
