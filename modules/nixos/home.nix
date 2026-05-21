{ inputs, ... }:
{
  flake.nixosModules.home =
    { ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.catppuccin.nixosModules.catppuccin
      ];

      services.flatpak.enable = true;
      programs.dconf.enable = true;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        overwriteBackup = true;
        sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];

        users.grey =
          { pkgs, lib, ... }:
          {
            home = {
              username = "grey";
              homeDirectory = "/home/grey";
              stateVersion = "26.05";
              packages = [ inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default ];

              pointerCursor = {
                package = pkgs.catppuccin-cursors.mochaMauve;
                name = "catppuccin-mocha-mauve-cursors";
                size = 24;
                gtk.enable = true;
              };
            };

            catppuccin = {
              enable = true;
              flavor = "mocha";
              accent = "mauve";
            };

            gtk = {
              enable = true;
              theme = {
                name = "catppuccin-mocha-mauve-standard";
                package = pkgs.catppuccin-gtk.override {
                  accents = [ "mauve" ];
                  variant = "mocha";
                };
              };
              iconTheme = lib.mkForce {
                name = "Adwaita";
                package = pkgs.adwaita-icon-theme;
              };
            };
          };
      };
    };
}
