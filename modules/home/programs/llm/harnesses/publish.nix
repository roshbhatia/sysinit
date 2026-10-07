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
      deck = deck.${name};
      launch = h.launch or { };
    }
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
}
