{ config, lib, pkgs, ... }:

let
  settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    
    # Disable the blank line at the start of the prompt
    # add_newline = false
    
    # You can also replace your username with a neat symbol like   or disable this
    # and use the os module below
    username = {
      show_always = true;
      style_user = "bg:#9A348E";
      style_root = "bg:#9A348E";
      format = "[$user ]($style)";
      disabled = false;
    };
    
    # An alternative to the username module which displays a symbol that
    # represents the current operating system
    os = {
      style = "bg:#9A348E";
      disabled = true; # Disabled by default
    };
    
    directory = {
      style = "bg:#DA627D";
      format = "[ $path ]($style)";
      truncation_length = 3;
      truncation_symbol = "…/";
      substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
      };
    };
    
    c = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    docker_context = {
      symbol = " ";
      style = "bg:#06969A";
      format = "[ $symbol $context ]($style)";
    };
    
    elixir = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    elm = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    git_branch = {
      symbol = "";
      style = "bg:#FCA17D";
      format = "[ $symbol $branch ]($style)";
    };
    
    git_status = {
      style = "bg:#FCA17D";
      format = "[$all_status$ahead_behind ]($style)";
    };
    
    golang = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    gradle = {
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    haskell = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    java = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    julia = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    nodejs = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    nim = {
      symbol = "󰆥 ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    rust = {
      symbol = "";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    scala = {
      symbol = " ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    time = {
      disabled = false;
      time_format = "%R"; # Hour:Minute Format
      style = "bg:#33658A";
      format = "[ ♥ $time ]($style)";
    };
  };
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = settings;
  };
}