{
  lib,
  pkgs,
  values,
  ...
}:

{
  # Enable stylix neovim target in home-manager
  stylix.targets.neovim = {
    enable = true;
    plugin = "base16-nvim";
    transparentBackground = {
      main = true;
      signColumn = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    # This will be combined with stylix's generated config
    initLua = ''
      -- Nix/home-manager management indicator
      vim.g.nix_hm_managed = true

      -- Theme info from Nix
      vim.g.nix_colorscheme = "${values.theme.colorscheme}"
      vim.g.nix_variant = "${values.theme.variant}"
      vim.g.nix_appearance = "${values.theme.appearance}"

      -- Copy content from init.lua below:
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"
      vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

      -- Filter out noisy/unhelpful error messages
      local original_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" then
          if msg:match("Invalid window id:") and msg:match("_extui/cmdline%.lua") then
            return
          end
          if msg:match("Flake input .* cannot be evaluated") then
            return
          end
          if msg:match("attempt to get length of local 'diagnostics'") then
            return
          end
        end
        return original_notify(msg, level, opts)
      end

      require("vim._extui").enable({})

      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.uv.fs_stat(lazypath) then
        vim.fn.system({
          "git",
          "clone",
          "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable",
          lazypath,
        })
      end

      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          -- Add base16-nvim directly to spec
          {
            "RRethy/base16-nvim",
            lazy = false,
            priority = 1000,
            config = function()
              -- Only set fallback theme if NOT Nix-managed
              if not vim.g.nix_hm_managed then
                vim.cmd.colorscheme("base16-macchiato")
              end
            end,
          },
          {
            import = "sysinit.plugins",
          },
        },
        install = {
          colorscheme = { "default" },
        },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "matchit",
              "matchparen",
              "netrwPlugin",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
        ui = {
          border = "rounded",
        },
      })
    '';
  };

  xdg = {
    configFile = {
      "nvim/after/ftplugin".source = ./after/ftplugin;
      "nvim/after/plugin/".source = ./after/plugin;
      "nvim/after/snippets/".source = ./after/snippets;
      "nvim/after/lsp/".source = ./after/lsp;
      "nvim/lua/sysinit/plugins/".source = ./lua/sysinit/plugins;
      "nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;
      "nvim/lua/sysinit/core".source = ./lua/sysinit/core;
      "nvim/queries".source = ./queries;
    };
  };
}
