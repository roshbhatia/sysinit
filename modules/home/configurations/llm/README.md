# Enhanced LLM Configuration System

## Overview

This document describes the enhanced LLM configuration system that provides comprehensive support for AGENTS.md integration, execution environment management, and advanced capabilities for AI coding agents.

## Key Features

### 1. AGENTS.md Integration ✅
- **Comprehensive AGENTS.md file** with project-specific guidance
- **Standardized agent instructions** following https://agents.md/ specification
- **Auto-update capabilities** for keeping AGENTS.md current
- **Cross-agent compatibility** for Claude, Goose, Opencode, and Cursor

### 2. Execution Environment ✅
- **Nix-shell integration** for dynamic dependency management
- **Wezterm session spawning** for command visibility
- **Resource monitoring** and logging
- **Sandboxed execution** for security
- **Timeout management** for long-running tasks

### 3. Enhanced System Prompts ✅
- **AGENTS.md references** in all agent prompts
- **Execution environment instructions** for dependency management
- **Best practices integration** with project conventions
- **Tool-specific guidance** for optimal usage

### 4. Comprehensive Configuration ✅
- **Complete values schema** for all LLM configurations
- **Modular architecture** for easy extension
- **Type safety** with Nix option validation
- **Environment-specific settings** support

## Architecture

```
modules/home/configurations/llm/
├── config/                    # LLM client configurations
│   ├── claude.nix            # Claude Desktop + MCP
│   ├── goose.nix             # Goose AI assistant
│   ├── opencode.nix          # Opencode IDE
│   └── cursor-agent.nix      # Cursor CLI permissions
├── prompts/                   # Enhanced agent prompts
│   ├── agent-organizer.nix   # With AGENTS.md integration
│   ├── ai-engineer.nix       # With execution environment
│   └── ...                  # Other specialized prompts
├── shared/                    # Common configurations
│   ├── execution.nix          # NEW: Execution environment
│   ├── mcp-servers.nix       # Enhanced with AGENTS.md
│   ├── lsp.nix              # Language server configuration
│   ├── prompts.nix          # Prompt management
│   └── common.nix           # Utility functions
└── default.nix               # Main entry point
```

## Usage Examples

### Dynamic Dependency Management
```bash
# Test new dependencies without installing globally
llm-exec --nix-shell --deps "ripgrep fd" -- rg "pattern" .

# Python development with specific packages
llm-exec --nix-shell --deps "python311Packages.langchain openai" -- python setup_llm.py

# Go development with tools
llm-exec --nix-shell --deps "go golangci-lint" -- go test ./...
```

### Visible Command Execution
```bash
# Spawn in new wezterm window for visibility
llm-exec --wezterm -- make test

# Long-running task with monitoring
llm-exec --wezterm --monitor --timeout 600 -- python train_model.py

# Development server with visibility
llm-exec --wezterm -- npm run dev
```

### Resource Monitoring
```bash
# Monitor resource usage
llm-exec --monitor -- python intensive_task.py

# Check execution logs
tail -f ~/.local/share/llm-exec.log

# Custom timeout
llm-exec --timeout 1200 -- make build
```

## Configuration

### Basic Setup
Add to your `values.nix`:

```nix
{
  llm = {
    agentsMd = {
      enabled = true;
      autoUpdate = true;
    };
    
    execution = {
      nixShell = {
        enabled = true;
        autoDeps = true;
        sandbox = true;
      };
      
      terminal = {
        wezterm = {
          enabled = true;
          newWindow = true;
          monitor = true;
        };
      };
    };
  };
}
```

### Advanced Configuration
See `modules/home/configurations/llm/example-values.nix` for comprehensive configuration options.

## Agent-Specific Features

### Claude Desktop
- **MCP Server Integration**: AWS services, development tools, Serena
- **AGENTS.md Support**: Automatic context loading
- **Enhanced Security**: Proper environment scoping

### Goose AI Assistant
- **Alpha Features**: Latest capabilities enabled
- **Smart Approval**: Optimized interaction mode
- **Agent Orchestration**: Built-in workflow management

### Opencode IDE
- **Theme Integration**: Consistent with system theme
- **LSP Support**: Full language server coverage
- **Agent Registry**: Access to specialized prompts

### Cursor CLI
- **Permission Management**: Granular command control
- **Vim Mode**: Enhanced editor experience
- **Shell Integration**: Seamless workflow

## Security Considerations

### Execution Isolation
- **Nix Sandbox**: Isolated package environments
- **Resource Limits**: Timeout and memory constraints
- **Logging**: Comprehensive audit trail
- **Permission Control**: Granular access management

### MCP Server Security
- **Regional Isolation**: AWS services region-scoped
- **Environment Variables**: Proper scoping
- **Error Handling**: Graceful failure management
- **Access Control**: Minimal privilege principle

## Best Practices

### For Development
1. **Use AGENTS.md conventions** for consistency
2. **Test dependencies with nix-shell** before installation
3. **Use wezterm spawning** for visibility during development
4. **Monitor resource usage** for optimization
5. **Review execution logs** for troubleshooting

### For Configuration
1. **Enable validation** for type safety
2. **Use modular structure** for maintainability
3. **Document custom configurations** for team sharing
4. **Test incrementally** for reliability
5. **Monitor performance** for optimization

## Troubleshooting

### Common Issues
1. **Dependency conflicts**: Use nix-shell isolation
2. **Permission errors**: Check Cursor CLI permissions
3. **MCP server failures**: Verify AWS credentials
4. **Build errors**: Validate values.nix syntax
5. **Performance issues**: Monitor resource usage

### Debug Commands
```bash
# Check configuration
task nix:build

# Test execution environment
llm-exec --no-sandbox -- echo "test"

# Check MCP servers
claude-desktop --list-mcp-servers

# Monitor logs
tail -f ~/.local/share/llm-exec.log
```

## Migration Guide

### From Previous Configuration
1. **Backup current values.nix**
2. **Add new llm section** to values.nix
3. **Update prompts** with AGENTS.md references
4. **Test execution environment** with llm-exec
5. **Apply configuration** with `task nix:refresh`

### Custom Prompts
1. **Create prompt file** in `prompts/` directory
2. **Follow enhanced structure** with AGENTS.md integration
3. **Add to prompts.nix** for registration
4. **Test with preferred LLM client**

## Performance Optimization

### Build Performance
- **Use binary cache** for faster builds
- **Enable parallel builds** where possible
- **Clean old generations** regularly
- **Use work configuration** for reduced footprint

### Runtime Performance
- **Optimize nix-shell usage** for dependency management
- **Monitor resource usage** for bottlenecks
- **Use appropriate timeouts** for task types
- **Leverage caching** where available

## Future Enhancements

### Planned Features
- **GPU acceleration** for ML workloads
- **Distributed execution** for large tasks
- **Advanced monitoring** with metrics dashboard
- **Auto-scaling** resources based on workload
- **Integration** with more LLM providers

### Extension Points
- **Custom MCP servers** for specialized tools
- **Additional prompts** for new domains
- **Execution environments** for different platforms
- **Monitoring integrations** for observability

## Support

### Documentation
- **AGENTS.md**: Project-specific guidance
- **README.md**: General project information
- **CLAUDE.md**: Development environment details

### Community
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Community support and ideas
- **Contributing**: Development guidelines and PR process

This enhanced LLM configuration system provides a robust foundation for AI-assisted development with proper isolation, monitoring, and AGENTS.md integration.