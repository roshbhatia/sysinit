[
  {
    name = "ai-engineer";
    description = "Builds LLM applications, RAG systems, and prompt pipelines. Implements vector search, agent orchestration, and AI API integrations.";
    promptFile = ./prompts/ai-engineer.md;
    tags = [
      "ai"
      "llm"
      "rag"
    ];
    tools = [
      "read"
      "write"
      "edit"
      "bash"
      "grep"
      "glob"
    ];
  }
  {
    name = "backend-architect";
    description = "Design RESTful APIs, microservice boundaries, and database schemas. Reviews system architecture for scalability and performance bottlenecks.";
    promptFile = ./prompts/backend-architect.md;
    tags = [
      "backend"
      "api"
      "architecture"
    ];
    tools = [
      "read"
      "write"
      "edit"
      "bash"
      "grep"
      "glob"
    ];
  }
  {
    name = "frontend-developer";
    description = "Build Next.js applications with React components, shadcn/ui, and Tailwind CSS. Expert in SSR/SSG, app router, and modern frontend patterns.";
    promptFile = ./prompts/frontend-developer.md;
    tags = [
      "frontend"
      "react"
      "nextjs"
    ];
    tools = [
      "read"
      "write"
      "edit"
      "bash"
      "grep"
      "glob"
    ];
  }
  {
    name = "typescript-expert";
    description = "Write type-safe TypeScript with advanced type system features, generics, and utility types. Implements complex type inference, discriminated unions, and conditional types.";
    promptFile = ./prompts/typescript-expert.md;
    tags = [
      "typescript"
      "type-safety"
      "js"
    ];
    tools = [
      "read"
      "write"
      "edit"
      "bash"
      "grep"
      "glob"
    ];
  }
]
