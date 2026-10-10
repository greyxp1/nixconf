{
  flake.nixosModules.tailscale = {
    services.tailscale = {
      enable = true;
      extraSetFlags = ["--operator=grey"];
    };
    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/tailscale";
        mode = "0700";
      }
    ];
  };
}
