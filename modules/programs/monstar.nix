{
  flake.homeModules.monstar = {
    config,
    pkgs,
    lib,
    ...
  }: let
    monstar = pkgs.stdenvNoCC.mkDerivation rec {
      pname = "monstar";
      version = "1.0.1";

      src = pkgs.fetchurl {
        url = "https://github.com/rockorager/monstar/releases/download/v${version}/monstar-${version}-x86_64-linux.tar.gz";
        hash = "sha256-Jx/PaNPmc1AyfrpDwGHwvZBOxOWnBJ7mDXyeeZkdS7w=";
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = with pkgs; [wayland fontconfig freetype harfbuzz libxkbcommon];
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp -r bin share "$out/"
        cp -r ${pkgs.ghostty.terminfo}/share/terminfo "$out/share/"
        runHook postInstall
      '';

      meta = {
        description = "Wayland terminal emulator built on libghostty";
        homepage = "https://github.com/rockorager/monstar";
        license = lib.licenses.mit;
        mainProgram = "monstar";
        platforms = ["x86_64-linux"];
      };
    };
  in {
    home.packages = [monstar];

    xdg.configFile."monstar/config".text = ''
      font-family = JetBrains Mono
      font-size = 14
      background-opacity = 0.8
      window-padding-x = 8
      window-padding-y = 8
      selection-background = #0078D7
      theme = catppuccin-${config.catppuccin.flavor}
    '';
    xdg.configFile."monstar/themes/catppuccin-${config.catppuccin.flavor}".source =
      pkgs.runCommand "monstar-catppuccin-${config.catppuccin.flavor}" {} ''
        sed '/^split-divider-color =/d' \
          ${config.catppuccin.sources.ghostty}/catppuccin-${config.catppuccin.flavor}.conf > "$out"
      '';
  };
}
