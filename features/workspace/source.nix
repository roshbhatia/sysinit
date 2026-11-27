{ lib }:
lib.fileset.toSource {
  root = ../..;
  fileset = lib.fileset.unions [
    ./.
    ../wezterm/mux.nu
    ../../modules/home/programs/llm/runtime/agents/catalog.nu
  ];
}
