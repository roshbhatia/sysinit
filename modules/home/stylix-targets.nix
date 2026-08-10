_:
# Every stylix target this repository overrides, in one place.
#
# They cannot live next to the programs they override: setting `stylix.targets.<name>`
# requires the option to EXIST, and stylix injects its home modules only when enabled.
# `lib.mkIf` makes a value conditional, not an option name, and `config ? stylix` at
# module level forces the option set mid-assembly, which is infinite recursion.
#
# So the whole file is imported or not, decided by the `theme` argument in
# `programs/default.nix`.
{
  stylix.targets = {
    # Helix draws its own background, so stylix's opacity pass doubles up.
    helix.opacity.enable = false;

    # The colorscheme is set by the neovim config itself, which is hand-kept so
    # it works on a box with no Nix.
    neovim.enable = false;

    vivid.enable = true;

    # Firefox is themed by the userChrome CSS in `programs/firefox.nix`, which
    # goes further than stylix's target does.
    firefox.enable = false;

    # Same: `programs/wezterm` writes a full color scheme rather than taking
    # stylix's.
    wezterm.enable = false;

    # waybar's CSS is written by `nixos/home/desktop.nix`.
    waybar.addCss = false;
  };
}
