# Cupcake Project Structure

This directory provides the minimal structure required for cupcake to work with global-only policies.

The actual policies and configuration are managed via:
- Global config: `~/.config/cupcake/rulebook.yml`
- Global policies: `~/.config/cupcake/policies/opencode/`

This project uses **global cupcake policies only** - no project-local policies are defined here.

The empty `policies/opencode/` directory is required for cupcake initialization, even when using global-only configs.
