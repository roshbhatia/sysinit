{
  lib,
  config,
  values,
  utils,
  ...
}:

with lib;

{
  config = {
    assertions = utils.values.validateAllConfigs values;

    warnings = utils.values.generateValidationWarnings values;
  };
}
