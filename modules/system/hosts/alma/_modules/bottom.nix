{lib, ...}: {
  programs.bottom.settings = {
    disk.mount_filter.is_list_ignored = lib.mkForce true;
    row = lib.mkForce [
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
                ratio = 2;
                type = "disk";
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
}
