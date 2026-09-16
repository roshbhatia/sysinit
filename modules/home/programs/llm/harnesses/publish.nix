# The harness registry, rendered for every consumer that is not Nix.
#
# Publish the whole entry, not a chosen subset. The subset is what let
# neovim, wezterm and seshy each keep a private copy of who the agents are,
# and each copy drifted from the registry independently.
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
  # A harness whose notify is "scrape" has no status on any channel when it is
  # missing here, and nothing else reports that. hermes was missing for months.
  assertions = [
    {
      assertion = missingDeck == [ ];
      message = "deck-patterns.nix is missing: ${lib.concatStringsSep ", " missingDeck}";
    }
    {
      assertion = strayDeck == [ ];
      message = "deck-patterns.nix names harnesses not in registry.nix: ${lib.concatStringsSep ", " strayDeck}";
    }
  ];

  xdg.configFile."sysinit/agents.json".source = pkgs.sysinit.writeJSON "harnesses-publish.json" {
    version = 2;
    agents = lib.sort (a: b: a.name < b.name) agents;
  };
}
