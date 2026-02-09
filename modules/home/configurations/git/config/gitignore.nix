_:

let
  # macOS system files
  macosPatterns = [
    ".AppleDouble"
    ".DS_Store"
    ".DocumentRevisions-V100"
    ".LSOverride"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".VolumeIcon.icns"
    "._*"
    ".com.apple.timemachine.donotpresent"
    ".fseventsd"
  ];

  # Editor and IDE files
  editorPatterns = [
    "*.swo"
    "*.swp"
    "*~"
    ".cursor/"
    ".idea/"
    ".vscode/"
    "tags"
  ];

  # Backup files
  backupPatterns = [
    "*.backup"
    "*.backup*"
    "*.bak"
    "*.bak*"
  ];

  # AI assistant directories and files
  aiAssistantPatterns = [
    "**/.goose/"
    ".beads/"
    ".bv/"
    ".claude/"
    ".goose/"
    ".goosehints"
    ".sysinit/"
    "*.crush/"
    "AGENTS.md"
    "CLAUDE.md"
    "CRUSH.md"
  ];

  # Development environment files
  devEnvPatterns = [
    ".direnv/"
    ".envrc"
    ".gitattributes"
    "shell.nix"
  ];

  # Node.js and JavaScript
  nodePatterns = [
    "node_modules/"
    "npm-debug.log"
    "yarn-debug.log"
    "yarn-error.log"
  ];

  # Miscellaneous
  miscPatterns = [
    "**/*.glossary.yml"
    "**/sgconfig.yaml"
    "**/sgconfig.yml"
    "*.log"
    "ast-grep/"
  ];

  gitignorePatterns =
    macosPatterns
    ++ editorPatterns
    ++ backupPatterns
    ++ aiAssistantPatterns
    ++ devEnvPatterns
    ++ nodePatterns
    ++ miscPatterns;

in
{
  home.file.".gitignore.global" = {
    text = builtins.concatStringsSep "\n" gitignorePatterns + "\n";
  };
}
