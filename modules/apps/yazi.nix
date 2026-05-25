{ ... }: {
  flake.nixosModules.yazi = { ... }: {
    home-manager.users.grey = { ... }: {
      programs.yazi = {
        enable = true;
        settings = {
          manager = {
            show_hidden = true;
            sort_by = "mtime";
          };
        };
      };
    };
  };
}
