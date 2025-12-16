{ lib }:

with lib;

{
  getFontPackage =
    pkgs: fontName:
    let
      fontMapping = {
        "TX-02" = pkgs.nerd-fonts.agave;
        "Agave Nerd Font" = pkgs.nerd-fonts.agave;
        "Agave Nerd Font Mono" = pkgs.nerd-fonts.agave;

        "MonaspaceNeon Nerd Font" = pkgs.nerd-fonts.monaspace;
        "MonaspaceArgon Nerd Font" = pkgs.nerd-fonts.monaspace;
        "MonaspaceXenon Nerd Font" = pkgs.nerd-fonts.monaspace;
        "MonaspaceRadon Nerd Font" = pkgs.nerd-fonts.monaspace;
        "MonaspaceKrypton Nerd Font" = pkgs.nerd-fonts.monaspace;

        "JetBrainsMono Nerd Font" = pkgs.nerd-fonts.jetbrains-mono;
        "JetBrainsMono Nerd Font Mono" = pkgs.nerd-fonts.jetbrains-mono;

        "FiraCode Nerd Font" = pkgs.nerd-fonts.fira-code;
        "FiraCode Nerd Font Mono" = pkgs.nerd-fonts.fira-code;

        "Iosevka Nerd Font" = pkgs.nerd-fonts.iosevka;
        "Iosevka Nerd Font Mono" = pkgs.nerd-fonts.iosevka;
        "IosevkaTerm Nerd Font" = pkgs.nerd-fonts.iosevka-term;

        "IoskeleyMono" = pkgs.ioskeleymono;
        "Ioskeley Mono" = pkgs.ioskeleymono;

        "Hack Nerd Font" = pkgs.nerd-fonts.hack;
        "Hack Nerd Font Mono" = pkgs.nerd-fonts.hack;

        "CaskaydiaCove Nerd Font" = pkgs.nerd-fonts.caskaydia-cove;
        "CaskaydiaMono Nerd Font" = pkgs.nerd-fonts.caskaydia-mono;

        "VictorMono Nerd Font" = pkgs.nerd-fonts.victor-mono;
        "VictorMono Nerd Font Mono" = pkgs.nerd-fonts.victor-mono;

        "GeistMono Nerd Font" = pkgs.nerd-fonts.geist-mono;

        "CommitMono Nerd Font" = pkgs.nerd-fonts.commit-mono;

        "MesloLGS Nerd Font" = pkgs.nerd-fonts.meslo-lg;
        "MesloLGS Nerd Font Mono" = pkgs.nerd-fonts.meslo-lg;

        "RobotoMono Nerd Font" = pkgs.nerd-fonts.roboto-mono;

        "UbuntuMono Nerd Font" = pkgs.nerd-fonts.ubuntu-mono;

        "InconsolataGo Nerd Font" = pkgs.nerd-fonts.inconsolata-go;
        "Inconsolata Nerd Font" = pkgs.nerd-fonts.inconsolata;

        "Symbols Nerd Font" = pkgs.nerd-fonts.symbols-only;
        "Symbols Nerd Font Mono" = pkgs.nerd-fonts.symbols-only;

        "DejaVu Sans" = pkgs.dejavu_fonts;
        "DejaVu Serif" = pkgs.dejavu_fonts;
        "DejaVuSansMono Nerd Font" = pkgs.nerd-fonts.dejavu-sans-mono;

        "0xProto Nerd Font" = pkgs.nerd-fonts._0xproto;

        "3270 Nerd Font" = pkgs.nerd-fonts._3270;

        "Terminus" = pkgs.terminus_font;
        "Terminus Font" = pkgs.terminus_font;
        "TerminessTTF Nerd Font" = pkgs.nerd-fonts.terminess-ttf;
      };
    in
    if hasAttr fontName fontMapping then
      fontMapping.${fontName}
    else
      trace "Warning: Unknown font '${fontName}', falling back to nerd-fonts.agave" pkgs.nerd-fonts.agave;

  getNormalizedFontName =
    fontName:
    let
      nameNormalization = {
        "TX-02" = "Agave Nerd Font";
        "Agave Nerd Font Mono" = "Agave Nerd Font";
      };
    in
    if hasAttr fontName nameNormalization then nameNormalization.${fontName} else fontName;
}
