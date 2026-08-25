{
  config,
  lib,
  ...
}: {
  systemd.user.services.t3code.Service.ExecSearchPath = lib.mkForce "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin";
}
