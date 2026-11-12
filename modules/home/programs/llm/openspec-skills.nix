{ pkgs }:
pkgs.runCommand "openspec-skills"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.openspec
      pkgs.coreutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export OPENSPEC_TELEMETRY=0
    export CI=true
    mkdir -p "$HOME" work && cd work
    git init -q .
    git config user.email nix@localhost
    git config user.name nix
    timeout 180 openspec init --tools claude --profile core --force < /dev/null > /dev/null

    for skill in openspec-propose openspec-apply-change openspec-explore openspec-archive-change; do
      test -s ".agents/skills/$skill/SKILL.md" || {
        echo "openspec init produced no $skill skill" >&2
        exit 1
      }
    done

    mkdir -p "$out/skills"
    cp -r .agents/skills/* "$out/skills/"
  ''
