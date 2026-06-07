{...}: {
  flake.nixosModules.neowall = {pkgs, ...}: let
    neowall = pkgs.stdenv.mkDerivation rec {
      pname = "neowall";
      version = "0.4.6";
      src = pkgs.fetchFromGitHub {
        owner = "1ay1";
        repo = "neowall";
        rev = "v${version}";
        hash = "sha256-esI7m5V6ISpoXllLNjb52TdVMKel4FKOKPa40n3rofo=";
      };
      nativeBuildInputs = with pkgs; [meson ninja pkg-config wayland-scanner];
      buildInputs = with pkgs; [
        wayland
        wayland-protocols
        libGL # EGL + GLES2 via libglvnd; try pkgs.mesa if this fails
        libpng
        libjpeg
        libX11
        libXrandr
      ];
    };
  in {
    home-manager.users.grey = {...}: {
      home.packages = [neowall];
      xdg.configFile."neowall/config.vibe".text = ''
        default {
          shader ${./shaders}
          shader_speed 0.05
        }
      '';
    };
  };
}
