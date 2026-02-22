{
  ...
}:

{
  programs.obsidian = {
    enable = true;

    vaults = {
      MainVault = {
        enable = true;
        target = "orgfiles"; # Relative to home directory

        settings = {
          app = {
            "vim-mode" = true;
          };

          communityPlugins = {
            "obsidian-vimrc-support" = {
              enable = true;
            };
            "obsidian-vimium" = {
              enable = true;
            };
            "obsidian-mermaid" = {
              enable = true;
            };
            "obsidian-code-emitter" = {
              enable = true;
            };
          };

          extraFiles = {
            ".obsidian.vimrc" = {
              text = ''
                set autoindent " Copy indent from current line when starting a new line
                set hlsearch " Highlight all matches
                set ignorecase " Ignore case in search patterns
                set incsearch " Highlight matches as you type
                set linebreak " Wrap lines at word boundaries
                set number " Show line numbers
                set relativenumber " Show relative line numbers
                set smartcase " Override 'ignorecase' if search pattern contains capital letters
                set smartindent " Smarter autoindenting
              '';
            };
          };
        };
      };
    };
  };
}
