{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [../_custom-modules/bottom.nix];
  programs.bottom = {
    enable = true;
    settings = {
      inherit ((lib.importTOML "${inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.bottom}/mocha.toml")) styles;
      temperature.sensor_filter.list = ["Tccd1"];
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
                  ratio = 1;
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
