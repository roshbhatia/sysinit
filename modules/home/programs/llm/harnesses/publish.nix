# The harness registry, rendered for every consumer that is not Nix.
#
# Publish the whole entry, not a chosen subset. The subset is what let
# neovim, wezterm and seshy each keep a private copy of who the agents are,
# and each copy drifted from the registry independently.
{ lib, ... }:
let
  registry = import ./registry.nix;
  deck = import ./deck-patterns.nix;

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
  xdg.configFile."sysinit/agents.json".text = builtins.toJSON {
    version = 2;
    agents = lib.sort (a: b: a.name < b.name) agents;
  };
}
