# The StylesPath that prose-gate reads.
#
# The rule set is stated once in pkgs/prose-style/rules.cue and exported here at
# build time, so there is no generated file to check in and nothing to drift.
#
# `vale sync` is the normal way to get a borrowed style, and it downloads at run
# time. A Nix build has no network and the hook has to work on a cold machine,
# so each borrowed style is a fixed-output derivation pinned by release tag.
final: _prev:
let
  inherit (final) lib;

  borrowed = [
    {
      name = "proselint";
      repo = "vale-cli/proselint";
      version = "v0.3.4";
      hash = "sha256-SLH7SBukT2UF1ENGsoP2zcdO/SNPkTu9sJvzRCD6uBw=";
    }
    {
      name = "write-good";
      repo = "vale-cli/write-good";
      version = "v0.4.1";
      hash = "sha256-KWDvEIYd3H3HYpKkln6zeJvwXKJPhiBC9tFfUzMoh/A=";
    }
    {
      name = "alex";
      repo = "vale-cli/alex";
      version = "v0.2.3";
      hash = "sha256-RAFMf2PUqLzoZ4jgdO24AzOptuugfl3SeySCO2nu1Qs=";
    }
    # Two styles out of one repository, so the asset name and the repository
    # name differ here and `repo` has to be stated rather than derived.
    #
    # Slop is the closer fit to this repository's own rule set: 17 rules against
    # the tells, 38 alerts across the 41 tracked .md files. STE ships 12
    # ASD-STE100 rules and 1015 alerts on the same files, so only the two rules
    # named in `ini` are switched on. The rest conflicts: `STE.Modals` rewrites
    # `should` and `may`, which RFC 2119 gives a fixed meaning, and
    # `STE.Contractions` bans the contractions `writing-tone` keeps on purpose.
    {
      name = "Slop";
      repo = "Syntaf/vale-llm-slop";
      version = "v0.1.0";
      hash = "sha256-vFzWon9ujpAoV4e5kIpZekx3nxv3XbqfBxhy/ewvh00=";
    }
    {
      name = "STE";
      repo = "Syntaf/vale-llm-slop";
      version = "v0.1.0";
      hash = "sha256-bqfOSNIFA4q0ftuwsoazJOe3Niypl2gUKAHb5OAhZqw=";
    }
  ];

  fetch =
    style:
    final.fetchurl {
      url = "https://github.com/${style.repo}/releases/download/${style.version}/${style.name}.zip";
      inherit (style) hash;
    };
in
{
  # Vale resolves StylesPath relative to the config file, so both configs and
  # the styles tree land in one directory.
  vale-styles =
    final.runCommand "vale-styles"
      {
        nativeBuildInputs = [
          final.cue
          final.unzip
        ];
        rules = ../pkgs/prose-style/rules.cue;
      }
      ''
        mkdir -p "$out/styles/Sysinit"

        cue vet "$rules"
        for name in $(cue export -e 'strings.Join([for k, _ in rules {k}], "\n")' --out text "$rules"); do
          cue export -e "rules.$name" --out yaml "$rules" > "$out/styles/Sysinit/$name.yml"
        done
        cue export -e 'ini' --out text "$rules" > "$out/vale.ini"
        cue export -e 'auditIni' --out text "$rules" > "$out/vale-audit.ini"

        ${lib.concatMapStringsSep "\n" (style: ''
          unzip -q ${fetch style} -d "$out/styles"
        '') borrowed}

        # An empty rule set or a style that failed to unpack would turn the gate
        # into a no-op, so fail the build here instead of at run time.
        if [ -z "$(ls -A "$out/styles/Sysinit")" ]; then
          echo "vale-styles: rules is empty in rules.cue" >&2
          exit 1
        fi
        for want in ${lib.concatMapStringsSep " " (s: s.name) borrowed}; do
          if [ ! -d "$out/styles/$want" ]; then
            echo "vale-styles: $want is missing from the styles tree" >&2
            exit 1
          fi
        done
      '';
}
