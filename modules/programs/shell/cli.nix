{inputs, ...}: {
  flake.nixosModules.shell = {pkgs, ...}: let
    starshipTheme = fromTOML (builtins.readFile ./starship.toml);
  in {
    programs.nh = {
      enable = true;
      flake = "/home/grey/nixconf";
      clean = {
        enable = true;
        extraArgs = "--keep-since 2d --keep 3";
      };
    };

    home-manager = {
      sharedModules = [inputs.nix-index-database.homeModules.nix-index];
      users.grey = {...}: {
        home.sessionVariables = {
          MANPAGER = "sh -c 'col -bx | bat -l man -p'";
          PAGER = "bat -p";
        };

        programs = {
          nix-index.enable = true;
          nix-index-database.comma.enable = true;

          zoxide = {
            enable = true;
            enableNushellIntegration = true;
            options = ["--cmd cd"];
          };

          starship = {
            enable = true;
            enableNushellIntegration = true;
            settings = starshipTheme;
          };

          bottom.enable = true;
          bottom.settings.flags = {
            group_processes = true;
            process_memory_as_value = true;
            case_sensitive = false;
            regex = true;
          };
        };

        home.packages = with pkgs; [
          curl
          lstr
          bat
          fastfetch
          zip
          unzip
          wget
          codex
          nerd-fonts.jetbrains-mono
          fzf
          dash
        ];
      };
    };
  };
}
