{ inputs, ... }: let mkHost = import ../_mkHost.nix inputs; in {
  flake.nixosConfigurations.desktop = mkHost {
    extraModules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      ./_audio.nix
      ./_virt.nix
    ];
    hostModule = { pkgs, lib, ... }: {
      networking.hostName = "desktop";
      custom.disk.device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B778557B959";

      # Kernel
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;

      # AMD CPU
      boot.kernelParams = [ "amd_pstate=active" ];
      powerManagement.cpuFreqGovernor = "performance";
      hardware.cpu.amd.updateMicrocode = true;

      # Boot / initrd
      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          systemd = {
            enable = true;
            network.wait-online.enable = false;
          };
        };
        kernelModules = [ "kvm-amd" ];
      };

      # Secure Boot
      boot = {
        loader.systemd-boot.enable = lib.mkForce false;
        lanzaboote = {
          autoGenerateKeys.enable = true;
          enable = true;
          pkiBundle = "/var/lib/sbctl";
          autoEnrollKeys = {
            enable = true;
            autoReboot = true;
          };
        };
      };

      system.activationScripts.sbctl-keys = {
        text = ''
          if [ ! -d /var/lib/sbctl ]; then
            ${pkgs.sbctl}/bin/sbctl create-keys
          fi
        '';
      };

      environment.systemPackages = with pkgs; [
        nvidia-vaapi-driver
        sbctl
      ];

      # NVIDIA
      services = {
        xserver.videoDrivers = [ "nvidia" ];
        acpid.enable = lib.mkForce false;
      };
      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        nvidiaSettings = false;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
      };
    };
  };
}
