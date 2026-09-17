final: prev: {
  taskwarrior-cli =
    final.runCommand "taskwarrior-cli-${prev.taskwarrior3.version}"
      {
        inherit (prev.taskwarrior3) version;
        nativeBuildInputs = [ final.perl ];
        meta = prev.taskwarrior3.meta // {
          mainProgram = "taskwarrior";
        };
      }
      ''
        mkdir -p "$out/bin"
        ln -s ${prev.taskwarrior3}/bin/task "$out/bin/taskwarrior"
        cp -r ${prev.taskwarrior3}/share "$out/share"
        chmod -R u+w "$out/share"
        mv "$out/share/man/man1/task.1.gz" "$out/share/man/man1/taskwarrior.1.gz"
        for entry in bash-completion/completions/task fish/vendor_completions.d/task.fish zsh/site-functions/_task; do
          source="$out/share/$entry"
          destination="$(dirname "$source")/$(basename "$source" | sed 's/task/taskwarrior/')"
          perl -pe 's/\btask\b/taskwarrior/g; s/\b_task/_taskwarrior/g' "$source" > "$destination"
          rm "$source"
        done
      '';
  taskwarrior-tui-private = final.symlinkJoin {
    name = "taskwarrior-tui-private-${prev.taskwarrior-tui.version}";
    paths = [ prev.taskwarrior-tui ];
    nativeBuildInputs = [ final.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/taskwarrior-tui" --prefix PATH : ${prev.taskwarrior3}/bin
    '';
  };
}
