{
  lib,
  ...
}:
let
  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = [
        "Shell(ls)"
        "Shell(rg)"
        "Shell(head)"
        "Shell(git show)"
        "Shell(wc)"
        "Shell(grep)"
        "Shell(cd)"
        "Shell(make)"
        "Shell(git diff)"
        "Shell(git status)"
        "Shell(tail)"
        "Shell(which)"
        "Shell(cat)"
        "Shell(pwd)"
        "Shell(mkdir)"
        "Shell(kubectl get)"
        "Shell(kubectl describe)"
        "Shell(kubectl logs)"
        "Shell(kubectl explain)"
        "Shell(kubectl api-resources)"
        "Shell(kubectl api-versions)"
        "Shell(kubectl cluster-info)"
        "Shell(kubectl version)"
        "Shell(kubectl config view)"
        "Shell(kubectl config get-contexts)"
        "Shell(kubectl config current-context)"
        "Shell(kubectl top)"
        "Shell(crossplane --version)"
        "Shell(crossplane xpkg)"
        "Shell(crossplane beta trace)"
        "Shell(crossplane beta validate)"
      ];
      deny = [ ];
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };
in
{
  home.activation.cursorCliConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/cursor"
    $DRY_RUN_CMD mkdir -p "$HOME/.cursor"

    cat > "$HOME/.config/cursor/cli-config.json" << 'EOF'
    ${cursorConfig}
    EOF

    cat > "$HOME/.cursor/cli-config.json" << 'EOF'
    ${cursorConfig}
    EOF
  '';
}
