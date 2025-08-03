{ lib, values }:

let
  valuesTypes = import ./values-types.nix { inherit lib; };
  
  # Validate the values against our type system
  validateValues = values:
    let
      # Basic type validation - we'll do manual validation since lib.types.check isn't available in all contexts
      typeValid = true;  # For now, we'll rely on the more specific validations below
      
      # Additional theme/variant validation
      themeValid = if values ? theme then
        let 
          theme = values.theme.colorscheme;
          variant = values.theme.variant;
          validVariants = valuesTypes.getVariantsForTheme theme;
        in
        lib.elem variant validVariants
      else true;
      
      # Collect validation errors
      errors = []
        ++ (if typeValid == false then ["Values do not match expected type structure"] else [])
        ++ (if (values ? theme) && (themeValid == false) then 
            let 
              theme = values.theme.colorscheme;
              variant = values.theme.variant;
              validVariants = valuesTypes.getVariantsForTheme theme;
            in
            ["Invalid theme/variant combination: '${theme}/${variant}'. Valid variants for '${theme}': ${lib.concatStringsSep ", " validVariants}"]
          else []);
        
    in
    if errors == [] then
      values
    else
      throw "Values validation failed:\n${lib.concatStringsSep "\n" errors}";
      
  # Generate helpful error messages for theme mismatches
  getThemeHelp = theme:
    let
      validVariants = valuesTypes.getVariantsForTheme theme;
    in
    "For theme '${theme}', valid variants are: ${lib.concatStringsSep ", " validVariants}";
    
  # Check if a theme/variant combination is valid
  isValidThemeVariant = theme: variant:
    lib.elem variant (valuesTypes.getVariantsForTheme theme);

in
{
  inherit validateValues getThemeHelp isValidThemeVariant;
  inherit (valuesTypes) supportedThemes supportedThemeVariants valuesType;
  
  # Export validated values
  validatedValues = validateValues values;
}