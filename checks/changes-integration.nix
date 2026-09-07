{ pkgs }:

pkgs.runCommand "changes-integration-check"
  {
    nativeBuildInputs = [
      pkgs.changes
      pkgs.changes-provider-git-notes
      pkgs.git
      pkgs.gnugrep
      pkgs.jq
      pkgs.neovim
    ];
  }
  ''
    test "$(changes --version)" = "0.10.1"

    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    export CHANGES_PROVIDERS_DIRECTORY="${pkgs.changes-provider-git-notes}/share/changes/providers"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" repository

    changes provider validate git-notes

    cd repository
    git init --quiet
    git config user.name "Changes integration test"
    git config user.email changes@example.invalid
    git remote add origin https://example.invalid/changes.git
    git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git config remote.origin.push refs/heads/main
    printf '%s\n' 'package main' > main.go
    git add main.go
    git commit --quiet -m baseline
    printf '%s\n' 'package main' 'func main() {}' > main.go
    git add main.go
    git commit --quiet -m fixture

    fetch_before=$(git config --get-all remote.origin.fetch)
    push_before=$(git config --get-all remote.origin.push)
    changes note add \
      --commit HEAD \
      --provider git-notes \
      --file main.go \
      --line 2 \
      --origin user \
      --author sysinit-test \
      --message 'Keep this entry point explicit' > note.json
    git notes --ref=refs/notes/changes show HEAD | grep -F 'Keep this entry point explicit'
    test "$(git config --get-all remote.origin.fetch)" = "$fetch_before"
    test "$(git config --get-all remote.origin.push)" = "$push_before"

    printf '%s\n' 'package main' 'func main() {' '}' > main.go
    changes workspace --refresh --no-symbols --quiet > workspace.json
    jq -e --arg root "$PWD" '
      .version == "changes.workspace/v1"
      and .repository.root == $root
      and .freshness.state == "fresh"
      and (.files | any(.path == "main.go"))
      and (.notes == null or (.notes | type == "array"))
      and (.history | type == "array")
      and (.rendered | type == "string")
    ' workspace.json > /dev/null
    test "$(git config --get-all remote.origin.fetch)" = "$fetch_before"
    test "$(git config --get-all remote.origin.push)" = "$push_before"

    cd ..
    mkdir -p "$TMPDIR/nvim-site/pack/hm/start"
    ln -s ${pkgs.changes-neovim-plugin} "$TMPDIR/nvim-site/pack/hm/start/changes.nvim"
    nvim --headless --clean -u NONE \
      --cmd 'set packpath^=$TMPDIR/nvim-site' \
      --cmd 'set noloadplugins' \
      -c 'luafile ${../modules/home/programs/neovim/config/after/plugin/changes.lua}' \
      -c 'lua assert(vim.fn.exists(":ChangesNote") == 2); assert(vim.fn.exists(":ChangesWorkspace") == 2); assert(vim.fn.exists(":ChangesWorkspaceDecorate") == 2)' \
      -c 'lua assert(type(require("changes.notes").setup) == "function"); local workspace = require("changes.workspace"); assert(type(workspace.setup) == "function"); assert(type(workspace.read) == "function"); assert(type(workspace.open) == "function"); assert(type(workspace.decorate) == "function")' \
      -c 'qa!'

    touch "$out"
  ''
