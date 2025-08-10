{ lib, config, values, utils, ... }:

with lib;

{
  config = {
    assertions = utils.validation.validateAllConfigs values;

    warnings = [
      (mkIf (values.theme.colorscheme == "solarized" && values.theme.variant == "light")
        "Light theme variants may have reduced readability in some applications")

      (mkIf (length values.yarn.additionalPackages > 10)
        "Large number of yarn packages (${toString (length values.yarn.additionalPackages)}) may slow system startup")

      (mkIf (values.theme.transparency.opacity < 0.5)
        "Very low opacity (${toString values.theme.transparency.opacity}) may affect readability")
    ];
  };
}
