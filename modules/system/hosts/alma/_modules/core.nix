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
    STARSHIP_CONFIG = nixos.environment.variables.STARSHIP_CONFIG;
  };
  environment.etc = {
    "starship.toml".source = nixos.environment.etc."starship.toml".source;
    gitconfig.text = nixos.environment.etc.gitconfig.text;
    "ssh/ssh_config".text = nixos.environment.etc."ssh/ssh_config".text;
    "xdg/lazygit/config.yml".source = nixos.environment.etc."xdg/lazygit/config.yml".source;
    "bat/config".source = nixos.environment.etc."bat/config".source;
  };
  programs.nh = nixos.programs.nh;
  environment.systemPackages = [
    pkgs.openssh
    (inputs.self.wrappers.helix.wrap {
      inherit pkgs;
      languages.language-server.nixd.config.options.nixos.expr = "(builtins.getFlake \"path:/home/grey/Projects/nixconf\").systemConfigs.alma.options";
    })
    (inputs.self.wrappers.bottom.wrap {
      inherit pkgs;
      settings.row = lib.mkForce (map resizeDisk (inputs.self.wrappers.bottom.wrap {inherit pkgs;}).configuration.settings.row);
      settings.disk.mount_filter.is_list_ignored = lib.mkForce true;
    })
  ];
}
