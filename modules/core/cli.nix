{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ../_nixos-modules/tlrc.nix
    inputs.ncr.nixosModules.default
    inputs.nix-index-database.nixosModules.nix-index
  ];

  environment = {
    systemPackages = with pkgs; [curl wget fzf fd ripgrep microfetch zoxide];
    etc."starship.toml".source = (pkgs.formats.toml {}).generate "starship.toml" config.programs.starship.settings;
    variables.STARSHIP_CONFIG = "/etc/starship.toml";
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      startWhenNeeded = true;
    };
    tailscale = {
      enable = true;
      extraSetFlags = ["--operator=grey"];
    };
  };

  programs = {
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

    ssh = {
      startAgent = true;
      extraConfig = ''
        Host *
          AddKeysToAgent yes
          IdentitiesOnly yes
        Host github.com gitlab.com codeberg.org
          User git
          IdentityFile ~/.ssh/id_ed25519
      '';
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

    starship = {
      enable = true;
      settings = fromTOML (builtins.readFile "${inputs.starship-config}/starship.toml");
    };
  };
}
