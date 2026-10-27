{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.server = mkHost "server" {
    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "usb_storage" "sd_mod"];
    users.users.grey.homeMode = "0710";
    systemd.tmpfiles.rules = ["a+ /home/grey - - - - u:jellyfin:--x,m::--x"];

    hardware = {
      cpu.intel.updateMicrocode = true;
      graphics.enable = true;
    };

    services.tailscale = {
      useRoutingFeatures = "server";
      extraSetFlags = ["--advertise-exit-node=true"];
    };

    imports = [
      (inputs.import-tree ../../core)
      ./_modules/jellyfin.nix
      ./_modules/livesync.nix
      ./_modules/docker/docker.nix
      ./_modules/freedns.nix
      ./_modules/website.nix
      ./_modules/cliproxyapi.nix
    ];
  };
}
