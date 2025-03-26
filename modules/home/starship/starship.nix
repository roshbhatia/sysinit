{ config, lib, pkgs, ... }:

let
  settings = {
    "$schema" = "https://starship.rs/config-schema.json";
    
  format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)\n$character"

    # Disable the blank line at the start of the prompt
    # add_newline = false
    
    # You can also replace your username with a neat symbol like   or disable this
    # and use the os module below
    username = {
      show_always = true;
      style_user = "bg:#f0f4f8 fg:#1e293b";
      style_root = "bg:#f0f4f8 fg:#dc2626";
      format = "[$user ]($style)";
      disabled = false;
    };
    
    # An alternative to the username module which displays a symbol that
    # represents the current operating system
    os = {
      style = "bg:#d8bfd8";
      disabled = true; # Disabled by default
    };
    
    directory = {
      style = "bg:#e2e8f0 fg:#1e293b";
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
      style = "bg:#94a3b8 fg:#1e293b";
      format = "[ $symbol ($version) ]($style)";
    };
    
    docker_context = {
      symbol = "";
      style = "bg:#64748b fg:#f8fafc";
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
      style = "bg:#cbd5e1 fg:#1e293b";
      format = "[ $symbol $branch ]($style)";
    };
    
    git_status = {
      style = "bg:#cbd5e1 fg:#1e293b";
      format = "[$all_status$ahead_behind ]($style)";
    };
    
    golang = {
      symbol = "";
      style = "bg:#94a3b8 fg:#1e293b";
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
      style = "bg:#94a3b8 fg:#1e293b";
      format = "[ $symbol ($version) ]($style)";
    };
    
    nim = {
      symbol = "󰆥 ";
      style = "bg:#86BBD8";
      format = "[ $symbol ($version) ]($style)";
    };
    
    rust = {
      symbol = "";
      style = "bg:#94a3b8 fg:#1e293b";
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
      style = "bg:#475569 fg:#f8fafc";
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