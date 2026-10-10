{
  inputs,
  lib,
  nixos,
  pkgs,
  ...
}: let
  resizeDisk = widget:
    widget
    // lib.optionalAttrs ((widget.type or "") == "disk") {ratio = 2;}
    // lib.optionalAttrs (widget ? child) {child = map resizeDisk widget.child;};
in {
  imports = [
    ./nixos.nix
    "${inputs.nixpkgs}/nixos/modules/programs/nh.nix"
    "${inputs.nixpkgs}/nixos/modules/services/misc/nix-gc.nix"
    (import ./_userServices.nix {
      ssh-agent = {
        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent";
          ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
          Restart = "on-failure";
        };
        Install.WantedBy = "default.target";
      };
    })
  ];
  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
    OPENCODE_CONFIG = nixos.environment.variables.OPENCODE_CONFIG;
  };
  programs.nh = nixos.programs.nh;
  systemd.services.t3code =
    (lib.getAttrs ["description" "wantedBy" "after" "environment" "serviceConfig"]
      nixos.systemd.services.t3code)
    // {
      environment =
        nixos.systemd.services.t3code.environment
        // {
          PATH = lib.mkForce "/run/system-manager/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";
        };
    };
  environment.systemPackages =
    [
      pkgs.gh
      (inputs.self.wrappers.helix.wrap {
        inherit pkgs;
        languages.language-server.nixd.config.options.nixos.expr = "(builtins.getFlake \"path:/home/grey/Projects/nixconf\").systemConfigs.alma.options";
      })
      (inputs.self.wrappers.bottom.wrap {
        inherit pkgs;
        settings.row = lib.mkForce (map resizeDisk (inputs.self.wrappers.bottom.wrap {inherit pkgs;}).configuration.settings.row);
        settings.disk.mount_filter.is_list_ignored = lib.mkForce true;
      })
    ]
    ++ map (wrapper: wrapper.wrap {inherit pkgs;}) (with inputs.self.wrappers; [
      lazygit
      openssh
      codex
      starship
      git
      delta
      yazi
    ]);
}
