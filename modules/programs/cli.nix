{inputs, ...}: {
  flake.nixosModules.cli = {pkgs, ...}: {
    nixpkgs.overlays = [inputs.nyxexprs.overlays.default];
    programs.nh = {
      enable = true;
      flake = "/home/grey/nixconf";
      clean.enable = true;
      clean.extraArgs = "--keep-since 2d --keep 3";
    };

    home-manager = {
      sharedModules = [inputs.nix-index-database.homeModules.nix-index];
      users.grey = {...}: {
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
          inputs.tack.packages.${stdenv.hostPlatform.system}.default
          curl
          zip
          unzip
          wget
          codex
          nerd-fonts.jetbrains-mono
          fzf
          fd
          jq # needed by done plugin
          tlrc
          ripgrep
          microfetch
          btop
          ani-cli
          swayimg
        ];
      };
    };
  };
}
