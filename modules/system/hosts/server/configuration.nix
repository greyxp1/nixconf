{inputs, ...}: let
  mkHost = import ../_mkHost.nix inputs;
in {
  flake.nixosConfigurations.server = mkHost "server" ({lib, ...}: {
    imports = [
      ./_modules/pelican.nix
      ./_modules/jellyfin.nix
      ./_modules/livesync.nix
      ./_modules/obsidian.nix
      ./_modules/docker.nix
    ];
    disko.devices.disk.main.device = import ./_device.nix;
    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "usb_storage" "sd_mod"];
    hardware.cpu.intel.updateMicrocode = true;

    services.pipewire.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
    services.sunshine.enable = lib.mkForce false;
    security.rtkit.enable = lib.mkForce false;

    users.users.grey = {
      homeMode = "0710";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNpHu5c/ykb/08PRxkU63jqkrn/F7FbSzHh6QqfnwC3 grey@desktop"
      ];
    };
    systemd.tmpfiles.rules = ["a+ /home/grey - - - - u:jellyfin:--x,m::--x"];
  });
}
