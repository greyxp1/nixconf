{ inputs, withSystem, ... }:
{
  flake.nixosConfigurations.vm = withSystem "x86_64-linux" (
    { config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        (
          { pkgs, lib, ... }:
          {
            networking.hostName = "vm";
            custom.disk.device = "/dev/vda";

            boot = {
              kernelModules = [ "virtio_gpu" ];
              initrd.availableKernelModules = [
                "virtio_pci"
                "virtio_blk"
                "virtio_scsi"
                "virtio_gpu"
                "virtio_balloon"
                "ahci"
                "sd_mod"
              ];
            };

            # seatd handles DRM device ownership — required for niri TTY backend in VM
            services.seatd = {
              enable = true;
              group = "seat";
            };

            # greetd must run niri-session after seatd is up
            systemd.services.greetd = {
              after = lib.mkForce [
                "multi-user.target"
                "seatd.service"
              ];
              wants = [ "seatd.service" ];
            };

            # Mesa provides the virtio Vulkan driver (Venus) inside the guest.
            hardware.graphics = {
              enable = true;
              extraPackages = with pkgs; [ mesa ];
            };

            services = {
              spice-vdagentd.enable = true;
              qemuGuest.enable = true;
            };

            environment = {
              sessionVariables = {
                WLR_NO_HARDWARE_CURSORS = "1";
                LIBSEAT_BACKEND = "seatd";
                # Force OpenGL apps through Zink → Venus instead of falling back to VirGL.
                # Zink translates OpenGL to Vulkan, which Venus then passes to the host GPU.
                MESA_LOADER_DRIVER_OVERRIDE = "zink";
                GALLIUM_DRIVER = "zink";
              };
              systemPackages = with pkgs; [
                spice-vdagent
                mesa-demos # vkcube / glxinfo for verifying Venus inside guest
                vulkan-tools # vulkaninfo to confirm virtio/Venus driver is active
              ];
            };
          }
        )
      ]
      ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
