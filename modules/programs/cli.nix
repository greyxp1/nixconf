{inputs, ...}: {
  flake.nixosModules.cli = {homeDirectory, ...}: {
    imports = [inputs.ncr.nixosModules.default];
    networking.firewall.allowedTCPPorts = [3773];
    programs = {
      ncr.enable = true;
      tack.enable = true;
      nh = {
        flake = "${homeDirectory}/Projects/nixconf";
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
      t3code.enable = true;

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

    home.packages = with pkgs; [
      curl
      zip
      unzip
      wget
      fzf
      fd
      ripgrep
      microfetch
      pandora-launcher
    ];
  };
}
