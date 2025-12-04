{ ... }:

let
  gitignorePatterns = [
    "!.aider.conf.yml"
    "!.aiderignore"
    "**/.goose/"
    "*.backup"
    "*.backup*"
    "*.bak"
    "*.bak*"
    "*.log"
    "*.swo"
    "*.swp"
    "*~"
    ".AppleDouble"
    ".DS_Store"
    ".DocumentRevisions-V100"
    ".LSOverride"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".VolumeIcon.icns"
    "._*"
    ".aider*"
    ".claude/"
    ".com.apple.timemachine.donotpresent"
    ".cursor/"
    ".direnv/"
    ".envrc"
    ".fseventsd"
    ".goose/"
    ".goosehints"
    ".idea/"
    ".serena/"
    ".sysinit/"
    ".vscode/"
    "AGENTS.md"
    "CLAUDE.md"
    "node_modules/"
    "npm-debug.log"
    "shell.nix"
    "yarn-debug.log"
    "yarn-error.log"
  ];

in
{
  home.file.".gitignore.global" = {
    text = builtins.concatStringsSep "\n" gitignorePatterns + "\n";
  };
}
