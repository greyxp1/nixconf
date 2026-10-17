{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../_nixos-modules/helix.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = [
      (pkgs.writeShellApplication {
        name = "nix-format";
        runtimeInputs = [pkgs.statix pkgs.alejandra];
        text = "statix fix -s | alejandra -q";
      })
      pkgs.mpls
      pkgs.nixd
      pkgs.lazygit
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.grey = {};
    users.root = {};
    sharedModules = [
      {
        home.stateVersion = "26.05";
        fonts.fontconfig.enable = false;
        systemd.user.enable = false;
        programs.helix = {
          enable = true;
          package = null;
          themes.catppuccin_transparent = {
            inherits = "catppuccin_mocha";
            "ui.background".bg = "none";
          };

          settings = {
            theme = "catppuccin_transparent";
            editor = {
              true-color = true;
              color-modes = true;
              default-yank-register = "+";
              continue-comments = false;
              cursor-shape = {
                normal = "bar";
                insert = "bar";
                select = "bar";
              };

              soft-wrap = {
                enable = true;
                wrap-indicator = "";
              };
            };

            keys.normal."C-g" = [
              ":new"
              ":insert-output lazygit"
              ":buffer-close!"
              ":redraw"
            ];
          };

          languages = {
            language-server.mpls = {
              command = "mpls";
              args = ["--theme" "catppuccin-mocha"];
            };
            language-server.nixd.config.options.nixos.expr = ''
              (builtins.getFlake "path:${config.programs.nh.flake}")
                .nixosConfigurations.${config.networking.hostName}.options
            '';

            language = [
              {
                name = "markdown";
                language-servers = ["mpls"];
              }
              {
                name = "nix";
                auto-format = true;
                formatter.command = "nix-format";
                language-servers = ["nixd"];
              }
            ];
          };
        };
      }
    ];
  };
}
