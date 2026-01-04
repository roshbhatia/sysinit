_:

let
  gitignorePatterns = [
    "!.aider.conf.yml"
    "!.aiderignore"
    "**/.goose/"
    "*.backup"
    "*.backup*"
    "*.bak"
    "*.bak*"
    "*.crush/"
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
    ".beads/"
    ".claude/"
    ".com.apple.timemachine.donotpresent"
    ".cursor/"
    ".direnv/"
    ".envrc"
    ".fseventsd"
    ".gitattributes"
    ".goose/"
    ".goosehints"
    ".idea/"
    ".serena/"
    ".sysinit/"
    ".vscode/"
    "AGENTS.md"
    "CLAUDE.md"
    "CRUSH.md"
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
