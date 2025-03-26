{ config, lib, pkgs, ... }:

let
  settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    
    format = ''
    [](#242529)$os$username[](bg:#414045 fg:#242529)$directory[](fg:#414045 bg:#303136)$git_branch$git_status[](fg:#303136 bg:#403f44)$c$golang$java$nodejs$rust[](fg:#403f44 bg:#4f4e53)$docker_context[](fg:#4f4e53 bg:#303136)$time[ ](fg:#303136)
    '';

    # Disable the blank line at the start of the prompt
    # add_newline = false
    
    # You can also replace your username with a neat symbol like   or disable this
    # and use the os module below
    username = {
      show_always = true;
      style_user = "bg:#242529";
      style_root = "bg:#242529";
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
      style = "bg:#414045";
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
      symbol = "";
      style = "bg:#4f4e53";
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
      style = "bg:#303136";
      format = "[ $symbol $branch ]($style)";
    };
    
    git_status = {
      style = "bg:#303136";
      format = "[$all_status$ahead_behind ]($style)";
    };
    
    golang = {
      symbol = "";
      style = "bg:#403f44";
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
      style = "bg:#403f44";
      format = "[ $symbol ($version) ]($style)";
    };
    
    nim = {
      symbol = "󰆥 ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    rust = {
      symbol = "";
      style = "bg:#403f44";
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
      style = "bg:#303136";
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