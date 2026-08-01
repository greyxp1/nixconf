{
  flake.homeModules.bottom = {
    programs.bottom = {
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
}
