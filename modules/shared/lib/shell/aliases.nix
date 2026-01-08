{
  navigation = {
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "~" = "cd ~";
  };

  listing = {
    l = "eza --icons=always -1";
    la = "eza --icons=always -1 -a";
    ll = "eza --icons=always -1 -a";
    ls = "eza";
    lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";
  };

  tools = {
    sudo = "sudo -E";
    tf = "terraform";
    y = "yazi";
    v = "nvim";
    g = "git";
    lg = "lazygit";
    diff = "diff --color";
    grep = "grep -s --color=auto";
    watch = "watch --quiet";
    cat = "bat";
    find = "fd";
    sg = "ast-grep";
  };

  shortcuts = {
    dl = "cd $HOME/Downloads";
    docs = "cd $HOME/Documents";
    dsk = "cd $HOME/Desktop";
    ghp = "cd $HOME/github/personal";
    ghpr = "cd $HOME/github/personal/roshbhatia";
    ghw = "cd $HOME/github/work";
    sysinit = "cd $HOME/github/personal/roshbhatia/sysinit";
  };
}
