_:
# Every stylix target this repository overrides, in one place.
#
# These used to be one line each in six unrelated modules. They are here because
# they cannot be written there: setting `stylix.targets.<name>` requires that
# option to EXIST, and it does not when stylix is off, since stylix injects its
# home modules only when it is enabled.
#
# `lib.mkIf` does not help. It makes a value conditional, not an option name, so
# the definition is still attached to an option that is not declared. Asking
# `config ? stylix` at module level does not help either: it forces the option
# set while the option set is still being assembled, which is infinite
# recursion, observed rather than reasoned about.
#
# So the whole file is imported or not, decided by the `theme` argument in
# `programs/default.nix`. That is the same shape phase 6 used for profiles, and
# for the same reason: `imports` is resolved before `config` exists.
#
# One consequence worth stating: this list is where a target override lives now,
# not next to the program it overrides. Grepping `stylix.targets` finds one file
# rather than six, which is the trade.
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
