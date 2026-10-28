{
  # Offloads builds to the server, which has twice the memory. Tailscale SSH authorizes
  # the connection, so the daemon needs no key of its own.
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "server";
        sshUser = "grey";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSVBKLzlKWVNabUJXZkZ2NDRXZlN5R2E5VWgwMCtDaU1FUWJzKzdlc1FrNU4=";
      }
    ];
    settings.builders-use-substitutes = true;
  };
}
