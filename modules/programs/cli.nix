{inputs, ...}: {
  flake = {
    nixosModules.cli = {pkgs, ...}: {
      imports = [inputs.ncr.nixosModules.default inputs.self.wrappers.bat.install inputs.self.wrappers.tlrc.install inputs.nix-index-database.nixosModules.nix-index];
      wrappers.bat.enable = true;
      wrappers.tlrc.enable = true;
      environment.systemPackages = (with pkgs; [curl wget fzf fd ripgrep microfetch zoxide]) ++ [inputs.monstar.packages.${pkgs.stdenv.hostPlatform.system}.default.terminfo];
      services.tailscale = {
        enable = true;
        extraSetFlags = ["--operator=grey"];
      };
      programs = {
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

    wrappers = {
      zsh = {...}: {imports = ["${inputs.wrapper-zsh}/wrapperModules/z/zsh/module.nix"];};

      bat = {pkgs, ...}: {
        imports = ["${inputs.wrapper-bat}/wrapperModules/b/bat/module.nix"];
        settings = {
          style = "numbers,changes,rule,snip";
          paging = "never";
          theme = "Catppuccin Mocha";
        };
        themes."Catppuccin Mocha" = "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.bat}/Catppuccin Mocha.tmTheme";
      };

      tlrc = {...}: {
        imports = ["${inputs.wrapper-tlrc}/wrapperModules/t/tlrc/module.nix"];
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
