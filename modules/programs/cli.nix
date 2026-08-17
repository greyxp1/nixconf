{inputs, ...}: {
  flake.nixosModules.cli = {config, ...}: {
    imports = [inputs.ncr.nixosModules.default];
    programs = {
      tack.enable = true;
      nh = {
        enable = true;
        flake = config.flake.location;
        clean = {
          enable = true;
          dates = "daily";
          extraArgs = "--optimise --keep 10";
        };
      };

      ncr = {
        enable = true;
        flake = config.flake.location;
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
      wget
      fzf
      fd
      tlrc
      ripgrep
      microfetch
      pandora-launcher
      heroic
    ];
  };
}
