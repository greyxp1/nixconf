{inputs, ...}: {
  flake = {
    nixosModules.cli = {pkgs, ...}: {
      imports = [inputs.ncr.nixosModules.default inputs.self.nixosModules.tlrc inputs.nix-index-database.nixosModules.nix-index];
      environment.systemPackages = with pkgs; [curl wget fzf fd ripgrep microfetch zoxide];
      services.tailscale = {
        enable = true;
        extraSetFlags = ["--operator=grey"];
      };
      programs = {
        bat = {
          enable = true;
          settings = {
            style = "numbers,changes,rule,snip";
            paging = "never";
            theme = "Catppuccin Mocha";
          };
        };
        nh = {
          enable = true;
          flake = "/home/grey/Projects/nixconf";
          clean = {
            enable = true;
            dates = "daily";
            extraArgs = "--optimise --keep 10";
          };
        };
        tack.enable = true;
        nix-index.enable = true;
        nix-index-database.comma.enable = true;

        ncr = {
          enable = true;
          flake = "/home/grey/Projects/nixconf";
        };
      };
    };

    nixosModules.tlrc = {...}: {
      imports = [./_nixos-modules/tlrc.nix];
      programs.tlrc = {
        enable = true;
        settings = {
          output = {
            show_title = false;
            compact = true;
            option_style = "short";
          };
          style = {
            bullet.color = "blue";
            example.color = "green";
            placeholder = {
              color.hex = "#fab387";
              italic = true;
            };
          };
        };
      };
    };
  };
}
