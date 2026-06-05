{...}: {
  flake.nixosModules.shell = {
    pkgs,
    lib,
    ...
  }: let
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

    home-manager.users.grey = {...}: {
      home.sessionVariables = {
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        PAGER = "bat -p";
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = ["--cmd cd"];
      };

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
        settings =
          starshipTheme
          // {
            format = builtins.replaceStrings ["\n$character"] ["$character"] starshipTheme.format;
            add_newline = false;
            palette = lib.mkForce starshipTheme.palette;
          };
      };

      programs.bottom = {
        enable = true;
        settings.flags = {
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
        eza
        dash
        tldr
      ];
    };
  };
}
