{
  lib,
  ...
}:

with lib;

{
  /*
    Standard transparency presets for theme configurations.

    Provides predefined transparency settings for consistent application
    across themes and applications.
  */

  /*
    Available transparency presets:
    - none: No transparency (opacity 1.0, no blur)
    - light: Subtle transparency (opacity 0.95, blur 20)
    - medium: Moderate transparency (opacity 0.85, blur 80)
    - heavy: Strong transparency (opacity 0.70, blur 120)
  */
  transparencyPresets = {
    none = {
      enable = false;
      opacity = 1.0;
      blur = 0;
    };
    light = {
      enable = true;
      opacity = 0.95;
      blur = 20;
    };
    medium = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
    heavy = {
      enable = true;
      opacity = 0.70;
      blur = 120;
    };
  };

  /*
    Contextual transparency presets for different use cases.

    These provide optimized transparency settings for specific activities:
    - coding: Balanced for development work (high readability)
    - reading: Optimized for reading/documentation (maximum visibility)
    - presentation: Full opacity for projection/sharing (no transparency)
    - focus: Enhanced focus with slight blur (reduced distractions)
  */
  contextualPresets = {
    coding = {
      enable = true;
      opacity = 0.90;
      blur = 60;
    };
    reading = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
    presentation = {
      enable = false;
      opacity = 1.0;
      blur = 0;
    };
    focus = {
      enable = true;
      opacity = 0.95;
      blur = 40;
    };
  };

  /*
    Get a transparency preset by name.

    Arguments:
      presetName: string - Name of the preset (none, light, medium, heavy)
      fallback: attrs - Optional fallback if preset not found

    Returns:
      attrs - Transparency configuration { enable, opacity, blur }
  */
  getTransparencyPreset = presetName: fallback: transparencyPresets.${presetName} or fallback;

  /*
    Get a contextual transparency preset by name.

    Arguments:
      contextName: string - Name of context (coding, reading, presentation, focus)
      fallback: attrs - Optional fallback if context not found

    Returns:
      attrs - Transparency configuration { enable, opacity, blur }
  */
  getContextualPreset = contextName: fallback: contextualPresets.${contextName} or fallback;

  /*
    Determine transparency based on current conditions.

    Arguments:
      conditions: attrs - Current environmental conditions
        {
          nvim_running: bool
          presentation_mode: bool
          focus_mode: bool
        }
      baseTransparency: attrs - Fallback transparency configuration

    Returns:
      attrs - Appropriate transparency configuration for conditions
  */
  selectTransparencyForConditions =
    conditions: baseTransparency:
    if conditions.nvim_running or false then
      contextualPresets.coding
    else if conditions.presentation_mode or false then
      contextualPresets.presentation
    else if conditions.focus_mode or false then
      contextualPresets.focus
    else
      baseTransparency;
}
