{
  schema = "https://opencode.ai/config.json";
  theme = "system";
  autoupdate = true;
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
}
