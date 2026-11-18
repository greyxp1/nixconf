{
  config,
  lib,
  pkgs,
  ...
}: let
  libraries = with pkgs; [
    fontconfig
    libGL
    libx11
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
  ];
  rune = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "rex-rune";
    version = "0.10.1";
    src = pkgs.fetchurl {
      url = "https://github.com/shuv1337/rex-rune/releases/download/v${finalAttrs.version}/rex-rune-${finalAttrs.version}-x86_64-linux-gnu.tar.gz";
      hash = "sha256-LVANeX6Wk3bL+r5L/hc7ozR9N+bO0P5qQ6ZXQ38HSw8=";
    };
    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
    buildInputs = libraries;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/rex-rune "$out/bin/rex-rune"
      install -Dm644 resources/dev.shuv.rex-rune.desktop "$out/share/applications/dev.shuv.rex-rune.desktop"
      for size in 32 128 256; do
        icon="''${size}x''${size}/apps/dev.shuv.rex-rune.png"
        install -Dm644 "resources/icons/$icon" "$out/share/icons/hicolor/$icon"
      done
      wrapProgram "$out/bin/rex-rune" \
        --set REX_RUNE_CHANNEL nix \
        --prefix PATH : ${lib.makeBinPath [pkgs.fontconfig pkgs.xdg-utils]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libraries}
      runHook postInstall
    '';
    meta.mainProgram = "rex-rune";
  });
  workspace = pkgs.writeText "rex-rune-workspace.json" (builtins.toJSON {
    font_family = "JetBrains Mono";
    font_size = 18;
    interface.toolbar = "hidden";
    pane_header = "hidden";
    sidebar_open = true;
    terminal_theme = "follow_chrome";
    updates.check = false;
    vertical_tabs = true;
  });
  yaziInit = pkgs.writeText "rex-yazi-init.lua" ("\n"
    + ''
      -- Rex Rune's rounded Powerline glyphs are shorter than a highlighted row.
      if os.getenv("TERM_PROGRAM") == "rex" then
        local function square_indicators()
          th.indicator.padding = { open = "█", close = "█" }
        end
        square_indicators()
        ps.sub("theme", square_indicators)
      end
    '');
in {
  options.programs.yazi.initLua = lib.mkOption {
    apply = initLua: pkgs.concatText "yazi-init.lua" (lib.optional (initLua != null) initLua ++ [yaziInit]);
  };

  config = {
    environment.systemPackages = [rune];

    security.nix-secrets.secrets."desktop/pixel-ssh-key".owner = "grey";
    programs.ssh = {
      extraConfig = ''
        Host pixel-9.tail1785c.ts.net
          User u0_a334
          Port 8022
          IdentityFile ${config.security.nix-secrets.secrets."desktop/pixel-ssh-key".path}
      '';
      knownHosts = {
        server-rex = {
          hostNames = ["server.tail1785c.ts.net"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJ/9JYSZmBWfFv44WfSyGa9Uh00+CiMEQbs+7esQk5N";
        };
        pixel-rex = {
          hostNames = ["[pixel-9.tail1785c.ts.net]:8022"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICZkdeP27AG1l3xZtC4LybEMNkep/dlW4Uc705CdUMHJ";
        };
      };
    };

    systemd.user.tmpfiles.rules = [
      "d %h/.config/rex-rune 0700 - - -"
      "C %h/.config/rex-rune/workspace.json 0600 - - - ${workspace}"
    ];

    programs.niri.settings.window-rules = [
      {
        matches = [{"app-id" = "^dev\\.shuv\\.rex-rune$";}];
        opacity = 0.8;
        background-effect = {
          blur = true;
          xray = false;
        };
      }
    ];
  };
}
