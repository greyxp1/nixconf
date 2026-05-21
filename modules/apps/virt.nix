{ ... }:
{
  flake.nixosModules.virt =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf (config.networking.hostName == "desktop") {

        environment.systemPackages = with pkgs; [
          spice-gtk

          (pkgs.writeScriptBin "create-nixos-vm" ''
            #!/bin/sh
            if [ -z "$1" ] || [ -z "$2" ]; then
              echo "Usage: create-nixos-vm <vm-name> <path-to-nixos-iso>"
              exit 1
            fi

            virt-install \
              --connect qemu:///system \
              --name "$1" \
              --memory 8192 \
              --vcpus 4 \
              --disk size=40,pool=default,bus=virtio \
              --os-variant=nixos-unstable \
              --boot uefi \
              --network network=default,model=virtio \
              --noautoconsole \
              --cdrom "$2" \
              --video virtio,accel3d=on \
              --graphics spice,listen=none,image.compression=off \
              --graphics egl-headless,gl.rendernode=/dev/dri/renderD128
          '')
        ];

        # Ensure the user has full hardware access to standard render nodes
        users.users.grey.extraGroups = [
          "libvirtd"
          "video"
          "render"
        ];

        programs.virt-manager.enable = true;
        programs.dconf.enable = true;

        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/virt-manager/virt-manager/connections" = {
                autoconnect = [ "qemu:///system" ];
                uris = [ "qemu:///system" ];
              };
            };
          }
        ];

        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            runAsRoot = true;

            # Fixes EGL_NOT_INITIALIZED: Exposes the host's Nvidia/OpenGL driver libraries to QEMU's sandbox
            package = pkgs.qemu_kvm.overrideAttrs (oldAttrs: {
              nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
              postInstall = (oldAttrs.postInstall or "") + ''
                wrapProgram $out/bin/qemu-system-x86_64 \
                  --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
              '';
            });

            verbatimConfig = ''
              cgroup_device_acl = [
                  "/dev/null", "/dev/full", "/dev/zero",
                  "/dev/random", "/dev/urandom",
                  "/dev/ptmx", "/dev/kvm",
                  "/dev/nvidiactl", "/dev/nvidia0",
                  "/dev/nvidia-modeset", "/dev/dri/renderD128"
              ]
            '';
          };
        };
      };
    };
}
