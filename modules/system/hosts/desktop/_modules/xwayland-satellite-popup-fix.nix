{
  # xwayland-satellite 0.8.2 regressed popup/dropdown menus (commit 3273a0f);
  # pin to the fix commit add2795 that restores Steam menus under Niri.
  nixpkgs.overlays = [
    (final: prev: {
      xwayland-satellite = assert final.lib.assertMsg (prev.xwayland-satellite.version == "0.8.2")
        "Nixpkgs updated xwayland-satellite: check whether it includes popup focus fix add2795134593faafce60e404a0a75df68e9ee0c and remove the desktop override if so.";
        prev.xwayland-satellite.overrideAttrs (finalAttrs: _: {
          version = "0.8.2-steamfix";
          src = final.fetchFromGitHub {
            owner = "Supreeeme";
            repo = "xwayland-satellite";
            rev = "add2795134593faafce60e404a0a75df68e9ee0c";
            hash = "sha256-0TxfMgqW0/BLD4M942c5DCKYrtPvzsPJwvdcco4LQUM=";
          };
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            hash = "sha256-s1gl9eR6Mt2QLrhfcowstPFjzwE/lz4PJhJzWYHoIHg=";
          };
        });
    })
  ];
}
