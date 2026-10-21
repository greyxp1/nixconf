{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.server = mkHost "server" {
    disko.devices.disk.main.device = import ./_device.nix;
    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "usb_storage" "sd_mod"];
    hardware.cpu.intel.updateMicrocode = true;
    hardware.graphics.enable = true;
    systemd.tmpfiles.rules = ["a+ /home/grey - - - - u:jellyfin:--x,m::--x"];

    users.users.grey = {
      homeMode = "0710";
      openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNpHu5c/ykb/08PRxkU63jqkrn/F7FbSzHh6QqfnwC3 grey@desktop"];
    };

    services.tailscale = {
      useRoutingFeatures = "server";
      extraSetFlags = ["--advertise-exit-node=true"];
    };

    imports = [
      (inputs.import-tree ../../core)
      ./_modules/pelican.nix
      ./_modules/jellyfin.nix
      ./_modules/livesync.nix
      ./_modules/obsidian.nix
      ./_modules/docker.nix
      ./_modules/freedns.nix
      ./_modules/website.nix
    ];
  };
}
