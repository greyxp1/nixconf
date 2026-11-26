let
  cache = import ../../core/_cache.nix;
in {
  # Temporary server cache, delete with harmonia.nix once laptop and alma are dropped.
  substituters = cache.substituters ++ ["https://greyxp1.root.sx/nix-cache"];
  trusted-public-keys = cache.trusted-public-keys ++ ["greyxp1.root.sx-1:6g4cMFPtBQhoHsPcDFw/aNl8xhR5yYoZyjYqrmOjxAA="];
}
