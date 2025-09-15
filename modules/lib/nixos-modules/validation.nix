{
  lib,
  values,
  ...
}:

let
  validation = import ../validation { inherit lib; };
in
{
  config = {
    assertions = validation.validateAllConfigs values;

    warnings = validation.generateValidationWarnings values;
  };
}
