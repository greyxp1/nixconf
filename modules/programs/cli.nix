{inputs, ...}: {
  flake.nixosModules.cli = {
    programs = {
      tack.enable = true;
      nh = {
        enable = true;
        flake = "/home/grey/nixconf";
        clean = {
          enable = true;
          dates = "daily";
          extraArgs = "--optimise --keep 10";
        };
      };
    };
  };

  flake.homeModules.cli = {pkgs, ...}: {
    imports = [inputs.nix-index-database.homeModules.nix-index];
    programs = {
      nix-index.enable = true;
      nix-index-database.comma.enable = true;

      bat = {
        enable = true;
        config.style = "numbers,changes,rule,snip";
        config.paging = "never";
      };

      zoxide = {
        enable = true;
        options = ["--cmd cd"];
      };

      eza = {
        enable = true;
        extraOptions = [
          "-l"
          "--icons"
          "--git"
          "--group-directories-first"
          "--time-style=relative"
          "--no-user"
          "--no-permissions"
        ];
      };

      bottom = {
        enable = true;
        settings.flags = {
          group_processes = true;
          process_memory_as_value = true;
          case_sensitive = false;
          regex = true;
        };
      };
    };

    xdg.configFile."tlrc/config.toml".text = ''
      [output]
      show_title = false
      compact = true
      option_style = "short"

      [style]
      bullet.color = "blue"
      example.color = "green"
      placeholder.color = { hex = "#fab387" } # Peach
      placeholder.italic = true
    '';

    home.packages = with pkgs; [
      inputs.waytator.packages.${stdenv.hostPlatform.system}.default
      curl
      zip
      unzip
      wget
      nerd-fonts.jetbrains-mono
      fzf
      fd
      tlrc
      ripgrep
      microfetch
      ani-cli
      pandora-launcher
      wl-clipboard
    ];
  };
}
