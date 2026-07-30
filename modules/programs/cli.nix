{inputs, ...}: {
  flake.nixosModules.cli = {homeDirectory, ...}: {
    networking.firewall.allowedTCPPorts = [3773];
    programs = {
      tack.enable = true;
      nh = {
        enable = true;
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

      bottom = {
        enable = true;
        settings = {
          processes = {
            columns = ["Name" "CPU%" "GPU%" "Mem%" "GMem%"];
            default_memory_value = true;
            default_grouped = true;
            regex = true;
          };
          disk.mount_filter = {
            is_list_ignored = false;
            list = ["^/(boot|nix)$"];
            regex = true;
          };
          temperature.sensor_filter.list = ["Tccd1"];
          row = [
            {
              ratio = 30;
              child = [{type = "cpu";}];
            }
            {
              ratio = 70;
              child = [
                {
                  child = [
                    {
                      ratio = 5;
                      type = "mem";
                    }
                    {type = "disk";}
                    {type = "temp";}
                  ];
                }
                {
                  type = "proc";
                  default = true;
                }
              ];
            }
          ];
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
      inputs.ncr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
