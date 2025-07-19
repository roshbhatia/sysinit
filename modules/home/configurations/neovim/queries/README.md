# Custom Treesitter Queries for Go Templating in YAML

This directory contains custom Treesitter queries to enhance syntax highlighting and language injection for YAML files containing Go templates, specifically supporting:

- **Crossplane Compositions** with function Go templating
- **Kustomize files** with Go template patches  
- **Helm values files** and templates with Go templating

## Files

### yaml/highlights.scm
- Custom highlighting patterns for Go template expressions in YAML
- Recognizes Crossplane, Kustomize, and Helm-specific constructs
- Highlights template functions, variables, and control structures
- Special highlighting for:
  - Crossplane functions like `setResourceNameAnnotation`, `fromCompositeFieldPath`
  - Helm functions like `include`, `toYaml`, `default`, `quote`
  - Kustomize fields like `resources`, `patches`, `transformers`

### yaml/injections.scm  
- Language injection rules to enable Go template syntax highlighting within YAML strings
- Injects `gotmpl` language into string values containing `{{...}}` expressions
- Handles both inline strings and multi-line block scalars
- Special handling for:
  - Crossplane function template blocks
  - Kustomize strategic merge patches
  - Helm template values

### gotmpl/highlights.scm
- Enhanced highlighting for Go template syntax with framework-specific functions
- Recognizes standard Go template functions (if, range, with, etc.)
- Highlights framework-specific helpers:
  - **Crossplane**: `setResourceNameAnnotation`, `fromCompositeFieldPath`, etc.
  - **Helm**: `include`, `template`, `toYaml`, `default`, `quote`, etc.
  - **Kustomize**: patch-related functions
- Proper syntax highlighting for variables, operators, and control flow
- Built-in object recognition (Values, Chart, Release for Helm; observed, desired for Crossplane)

## File Detection

Files are automatically detected and enhanced based on:

### Crossplane
- API versions containing `crossplane.io` or `fn.crossplane.io`
- Resource kinds like `Composition`, `Function`
- Presence of `functionRef` or `gotemplating.fn.crossplane.io`

### Kustomize  
- Files named `kustomization.yaml/yml`
- API version `kustomize.config.k8s.io`
- Files containing `resources`, `patches`, etc.

### Helm
- Files named `values.yaml/yml`, `Chart.yaml/yml`
- Files in `templates/` directories
- Files containing Helm template functions

## Installation

These queries are automatically managed by the Nix configuration and symlinked to `~/.config/nvim/queries/`. 

Ensure you have the required Treesitter parsers:

```lua
ensure_installed = {
  "yaml",
  "gotmpl", 
  -- ... other parsers
}
```

## Testing

Use the provided test files to verify syntax highlighting:
- `validation/crossplane-composition.yaml` - Crossplane with Go templating
- `validation/kustomization.yaml` - Kustomize with template patches
- `validation/values.yaml` - Helm values with templating