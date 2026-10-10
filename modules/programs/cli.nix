{inputs, ...}: {
  flake.nhModule = {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/programs/nh.nix"
      "${inputs.nixpkgs}/nixos/modules/services/misc/nix-gc.nix"
    ];
    programs.nh = {
      enable = true;
      flake = "/home/grey/Projects/nixconf";
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--optimise --keep 10";
      };
    };
  };

  flake.nixosModules.cli = {pkgs, ...}: {
    imports = [inputs.self.nhModule inputs.ncr.nixosModules.default inputs.self.wrappers.bat.install inputs.self.wrappers.tlrc.install inputs.nix-index-database.nixosModules.nix-index inputs.self.nixosModules.monstar-terminfo];
    wrappers.bat.enable = true;
    wrappers.tlrc.enable = true;
    environment.systemPackages = with pkgs; [curl wget fzf fd ripgrep microfetch zoxide];
    programs = {
      tack.enable = true;
      nix-index.enable = true;
      nix-index-database.comma.enable = true;

      ncr = {
        enable = true;
        flake = "/home/grey/Projects/nixconf";
      };
    };
  };

  flake.wrappers.zsh = {...}: {imports = ["${inputs.wrapper-zsh}/wrapperModules/z/zsh/module.nix"];};

  flake.wrappers.bat = {pkgs, ...}: {
    imports = ["${inputs.wrapper-bat}/wrapperModules/b/bat/module.nix"];
    settings = {
      style = "numbers,changes,rule,snip";
      paging = "never";
      theme = "Catppuccin Mocha";
    };
    themes."Catppuccin Mocha" = "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.bat}/Catppuccin Mocha.tmTheme";
  };

  flake.wrappers.tlrc = {...}: {
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
}
