{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Nushell configuration module
  # Creates supporting directory structure for user customization

  # Create user autoload directory for user-specific nushell scripts
  home.file.".config/nushell/autoload/.keep".text = "";

  # Optional: Create template for secrets file
  home.activation.createNushellSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        SECRETS_FILE="$HOME/.nushell-secrets.nu"
        if [ ! -f "$SECRETS_FILE" ]; then
          $DRY_RUN_CMD cat > "$SECRETS_FILE" << 'EOF'
    # Nushell secrets file
    # Add sensitive environment variables here (not tracked in git)
    # Syntax: $env.VARIABLE_NAME = "value"

    # Example:
    # $env.API_KEY = "your-api-key-here"
    # $env.DATABASE_URL = "postgresql://user:pass@host/db"
    # $env.GITHUB_TOKEN = "ghp_xxxxxxxxxxxxx"
    EOF
          $DRY_RUN_CMD chmod 600 "$SECRETS_FILE"
          $VERBOSE_ECHO "Created nushell secrets template at $SECRETS_FILE"
        fi
  '';
}
