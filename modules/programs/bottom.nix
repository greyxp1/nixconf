{
  config,
  inputs,
  ...
}: {
  flake.nixosModules.bottom = {
    imports = [config.flake.wrappers.bottom.install];
    wrappers.bottom.enable = true;
  };

  flake.wrappers.bottom = {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }: {
    imports = [wlib.wrapperModules.bottom];
    options.diskRatio = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
    };
    config.settings = {
      styles = (lib.importTOML "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.bottom}/mocha.toml").styles;
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
                {
                  type = "disk";
                  ratio = config.diskRatio;
                }
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
}
