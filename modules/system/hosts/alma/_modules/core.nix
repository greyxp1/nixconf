{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.self.nhModule
    inputs.self.t3codeSystemModule
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
  };
  environment.systemPackages =
    inputs.self.cliPackages pkgs
    ++ [
      pkgs.gh
      inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-db
      inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.comma-with-db
      (inputs.self.wrappers.helix.wrap {
        inherit pkgs;
        nixconfSystem = "systemConfigs.alma";
      })
      (inputs.self.wrappers.bottom.wrap {
        inherit pkgs;
        diskRatio = 2;
        settings.disk.mount_filter.is_list_ignored = lib.mkForce true;
      })
    ]
    ++ map (wrapper: wrapper.wrap {inherit pkgs;}) (with inputs.self.wrappers; [
      bat
      tlrc
      lazygit
      openssh
      codex
      starship
      git
      delta
    ]);
}
