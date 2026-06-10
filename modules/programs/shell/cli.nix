{inputs, ...}: {
  flake.nixosModules.shell = {pkgs, ...}: {
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
          bat.enable = true;
          bat.config.style = "numbers,changes,rule,snip";
          starship.enable = true;
          starship.settings = fromTOML (builtins.readFile ./starship.toml);
          zoxide.enable = true;
          zoxide.options = ["--cmd cd"];
          eza.enable = true;
          eza.extraOptions = [
            "-l"
            "--icons"
            "--git"
            "--group-directories-first"
            "--time-style=relative"
            "--no-user"
            "--no-permissions"
          ];

          bottom.enable = true;
          bottom.settings.flags = {
            group_processes = true;
            process_memory_as_value = true;
            case_sensitive = false;
            regex = true;
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
          curl
          fastfetch
          zip
          unzip
          wget
          codex
          nerd-fonts.jetbrains-mono
          fzf
          tlrc
          ripgrep
        ];
      };
    };
  };
}
