{
  lib,
  pkgs,
  cudaSupport ? false,
}: old: {
  patches = (old.patches or []) ++ [./sunshine-keyboard.patch];
  cmakeFlags = (old.cmakeFlags or []) ++ ["-DSUNSHINE_ENABLE_TRAY=OFF"];
  buildInputs = lib.filter (input: !(builtins.elem input [pkgs.qt6.qtbase pkgs.qt6.qtsvg])) old.buildInputs;
  nativeBuildInputs = lib.filter (input: input != pkgs.qt6.wrapQtAppsHook) old.nativeBuildInputs;
  postFixup = lib.optionalString cudaSupport ''
    wrapProgram $out/bin/sunshine \
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [pkgs.vulkan-loader]}
  '';
}
