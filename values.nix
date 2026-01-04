_: {
  values = {
    config.root = ./.;

    user.username = "user";

    git = {
      name = "Your Name";
      email = "your.email@example.com";
      username = "yourusername";
    };

    theme = {
      appearance = "dark";
      colorscheme = "catppuccin-mocha";
      variant = "mocha";
    };
  };
}
