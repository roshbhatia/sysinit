{ lib, pkgs, ... }:
let
  registry = import ./registry.nix;
  deck = import ./deck-patterns.nix;

  missingDeck = lib.subtractLists (lib.attrNames deck) (lib.attrNames registry);
  strayDeck = lib.subtractLists (lib.attrNames registry) (lib.attrNames deck);

  agents = lib.mapAttrsToList (
    name: h:
    {
      inherit name;
      inherit (h)
        label
        glyph
        command
        acp
        notify
        editBus
        guard
        projectDir
        transcriptRoot
        exitHook
        context
        ;
    }
    // {
      contextKey = h.contextKey or [ ];
      contextStyle = h.contextStyle or null;
      deck = deck.${name};
      launch = h.launch or { };
    }
  ) registry;
  instructionRows = lib.mapAttrsToList (
    _name: h:
    "| ${h.label} | `${h.context}`"
    + lib.optionalString ((h.contextKey or [ ]) != [ ]) " at `${lib.concatStringsSep "." h.contextKey}`"
    + " | ${if h ? contextStyle then "`${h.contextStyle}`" else "Included in instructions"} |"
  ) registry;
in
{

  assertions = [
    {
      assertion = missingDeck == [ ];
      message = "deck-patterns.nix is missing: ${lib.concatStringsSep ", " missingDeck}";
    }
    {
      assertion = strayDeck == [ ];
      message = "deck-patterns.nix names harnesses not in registry.nix: ${lib.concatStringsSep ", " strayDeck}";
    }
    {
      assertion = lib.all (
        d:
        builtins.isAttrs d.status_patterns
        && lib.all (
          key:
          builtins.elem key [
            "working"
            "waiting"
            "idle"
          ]
          && builtins.isList d.status_patterns.${key}
          && lib.all builtins.isString d.status_patterns.${key}
        ) (builtins.attrNames d.status_patterns)
      ) (builtins.attrValues deck);
      message = "Agent status patterns must map working, waiting, or idle to string lists";
    }
  ];

  xdg.configFile."sysinit/agents.json".source = pkgs.sysinit.writeJSON "harnesses-publish.json" {
    version = 2;
    agents = lib.sort (a: b: a.name < b.name) agents;
  };

  xdg.configFile."sysinit/instructions.md".text = ''
    # Agent instruction locations

    Shared working rules: `modules/home/programs/llm/lib/instructions.nix`.
    Shared output style: `modules/home/programs/llm/lib/output-style.nix`.
    Edit these Nix sources in sysinit; activation generates the harness files below.
    Claude loads its output style separately. Other harnesses receive it in their instructions.
    This table is generated from the harness registry.

    | Harness | Instructions | Output style |
    | --- | --- | --- |
    ${lib.concatStringsSep "\n" instructionRows}
  '';
}
