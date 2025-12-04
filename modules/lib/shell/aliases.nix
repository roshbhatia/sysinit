# Shared shell aliases and shortcuts
# This is a data structure that can be adapted for both zsh and nushell
{
  # Navigation aliases
  navigation = {
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "~" = "cd ~";
  };

  # File listing aliases
  listing = {
    l = "eza --icons=always -1";
    la = "eza --icons=always -1 -a";
    ll = "eza --icons=always -1 -a";
    ls = "eza";
    lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";
  };

  # Tool shortcuts
  tools = {
    code = "code-insiders";
    c = "code-insiders";
    kubectl = "kubecolor";
    tf = "terraform";
    y = "yazi";
    v = "nvim";
    g = "git";
    diff = "diff --color";
    grep = "grep -s --color=auto";
    watch = "watch --quiet";
    cat = "bat";
    find = "fd";
  };

  # Shortcuts (environment-changing functions)
  shortcuts = {
    dl = "cd $HOME/Downloads";
    docs = "cd $HOME/Documents";
    dsk = "cd $HOME/Desktop";
    ghp = "cd $HOME/github/personal";
    ghpr = "cd $HOME/github/personal/roshbhatia";
    ghw = "cd $HOME/github/work";
    nvim = "cd $HOME/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim";
    sysinit = "cd $HOME/github/personal/roshbhatia/sysinit";
  };
}
