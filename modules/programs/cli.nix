{inputs, ...}: {
  flake.nixosModules.cli = {homeDirectory, ...}: {
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

  flake.homeModules.cli = {
    osConfig,
    pkgs,
    ...
  }: {
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

      codex = {
        enable = true;
        settings = {
          approval_policy = "on-request";
          sandbox_mode = "danger-full-access";
          check_for_update_on_startup = false;
          model = "gpt-5.6-sol";
          model_reasoning_effort = "high";
          notice.hide_full_access_warning = true;
          notice.hide_rate_limit_model_nudge = true;
          projects.${osConfig.programs.nh.flake}.trust_level = "trusted";
          tui.show_tooltips = false;
          developer_instructions = ''
            Default to YAGNI: reuse existing code and packages, avoid new dependencies
            and custom implementations, and make the smallest correct diff.
            Run at most one narrowly scoped verification command, and only when it
            directly verifies the change. Do not run broad builds or full test suites
            when a narrower check exists. If an activation command already builds or
            validates the change, do not run a separate build first.
          '';
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
