{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ../_custom-modules/tlrc.nix
    inputs.ncr.nixosModules.default
    inputs.sonora.nixosModules.default
    inputs.nix-index-database.nixosModules.nix-index
  ];

  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=grey"];
  };
  preservation.preserveAt."/persistent".directories = [
    {
      directory = "/var/lib/tailscale";
      mode = "0700";
    }
  ];

  environment.systemPackages = with pkgs; [curl wget fzf fd ripgrep microfetch];

  programs = {
    direnv.enable = true;
    tack.enable = true;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    tlrc = {
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

    sonora = {
      enable = true;
      settings = {
        tray_icon = false;
        provider = "youtube";
        appearance = {
          transparent = true;
          transparency = 0.2;
        };
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

    bat = {
      enable = true;
      settings = {
        style = "numbers,changes,rule,snip";
        paging = "never";
        theme = "Catppuccin Mocha";
      };
    };

    ncr = {
      enable = true;
      flake = config.programs.nh.flake;
    };

    zoxide = {
      enable = true;
      flags = ["--cmd cd"];
    };
  };
}
