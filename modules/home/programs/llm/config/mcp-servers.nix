_: {
  sysinit.llm.mcp.additionalServers = {
    ast-grep = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/ast-grep/ast-grep-mcp"
        "ast-grep-server"
      ];
      description = "AST-based structural code search and analysis";
    };

    playwright = {
      command = "npx";
      args = [
        "-y"
        "@playwright/mcp@latest"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };

    aws-knowledge-mcp-server = {
      type = "http";
      url = "https://knowledge-mcp.global.api.aws";
      description = "AWS documentation and service knowledge";
    };

    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
      description = "Figma design files";
    };

    granola = {
      type = "http";
      url = "https://mcp.granola.ai/mcp";
      description = "Granola meeting notes and transcripts";
    };

    incidentio = {
      type = "http";
      url = "https://mcp.incident.io/mcp";
      description = "incident.io incident management";
    };

    launchdarkly = {
      type = "http";
      url = "https://mcp.launchdarkly.com/mcp/fm";
      description = "LaunchDarkly feature flag management";
    };

    launchdarkly-ai-configs = {
      type = "http";
      url = "https://mcp.launchdarkly.com/mcp/aiconfigs";
      description = "LaunchDarkly AI configuration management";
    };

    linear-server = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
      description = "Linear issue tracking";
    };

    lucidchart = {
      type = "http";
      url = "https://mcp.lucid.app/mcp";
      description = "Lucidchart diagramming";
    };

    notion = {
      type = "http";
      url = "https://mcp.notion.com/mcp";
      description = "Notion workspace and documentation";
    };

    slack = {
      type = "http";
      url = "https://mcp.slack.com/mcp";
      description = "Slack messaging";
    };

    supabase = {
      type = "http";
      url = "https://mcp.supabase.com/mcp";
      description = "Supabase database and backend";
    };

    vantage = {
      type = "http";
      url = "https://mcp.vantage.sh/mcp";
      description = "Vantage cloud cost management";
    };

    vercel = {
      type = "http";
      url = "https://mcp.vercel.com";
      description = "Vercel deployment and hosting";
    };

    wiz = {
      type = "http";
      url = "https://mcp.app.wiz.io";
      description = "Wiz cloud security";
    };
  };
}
