{
  inputs,
  lib,
  ...
}: let
  sunshinePkgs = inputs.sunshine-nixpkgs.legacyPackages.x86_64-linux;
  sunshineOverride = {cudaSupport ? false}: old: {
    postPatch = (old.postPatch or "") + ''
      cp -r ${inputs.libvirtualhid}/. third-party/libvirtualhid/
    '';
    preBuild = (old.preBuild or "") + ''
      # Keep C++ compilation within the build slice's memory budget.
      NIX_BUILD_CORES=$((NIX_BUILD_CORES > 2 ? 2 : NIX_BUILD_CORES))
    '';
    cmakeFlags = (old.cmakeFlags or []) ++ ["-DSUNSHINE_ENABLE_TRAY=OFF"];
    buildInputs = lib.filter (input: !(builtins.elem input [sunshinePkgs.qt6.qtbase sunshinePkgs.qt6.qtsvg])) old.buildInputs;
    nativeBuildInputs = lib.filter (input: input != sunshinePkgs.qt6.wrapQtAppsHook) old.nativeBuildInputs;
    postFixup = lib.optionalString cudaSupport ''
      wrapProgram $out/bin/sunshine \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [sunshinePkgs.vulkan-loader]}
    '';
  };
  sunshine = sunshinePkgs.sunshine.overrideAttrs (sunshineOverride {});
  mkSunshineDisplay = pkgs: pkgs.writeShellApplication {
    name = "sunshine-display";
    runtimeInputs = [pkgs.niri pkgs.jq];
    text = ''
      state="''${XDG_RUNTIME_DIR:?}/sunshine-display-mode"
      umask 077

      restore() {
        if [[ -f "$state" ]]; then
          IFS=$'\t' read -r output mode scale < "$state"
          niri msg output "$output" mode "$mode"
          niri msg output "$output" scale "$scale"
          rm -- "$state"
        fi
      }

      case "''${1:?Expected start or restore}" in
        start)
          [[ "''${SUNSHINE_APP_NAME:-}" == Desktop ]] || exit 0
          : "''${SUNSHINE_CLIENT_WIDTH:?}" "''${SUNSHINE_CLIENT_HEIGHT:?}" "''${SUNSHINE_CLIENT_FPS:?}"
          if [[ ! -f "$state" ]]; then
            niri msg --json outputs | jq -er '
              [.[] | select(.logical != null)]
              | sort_by(if .logical.x == 0 and .logical.y == 0 then 0 else 1 end)
              | first | .modes[.current_mode] as $mode
              | [.name, "\($mode.width)x\($mode.height)@\($mode.refresh_rate / 1000)", .logical.scale]
              | @tsv
            ' > "$state.tmp"
            mv -- "$state.tmp" "$state"
          fi
          IFS=$'\t' read -r output mode scale < "$state"
          trap restore ERR
          target=$(niri msg --json outputs | jq -er --arg output "$output" \
            --argjson width "''${SUNSHINE_CLIENT_WIDTH:?}" \
            --argjson height "''${SUNSHINE_CLIENT_HEIGHT:?}" \
            --argjson fps "''${SUNSHINE_CLIENT_FPS:?}" '
              .[$output] as $display
              | [$display.modes[] | select(.width == $width and .height == $height)] as $matching
              | (if ($matching | length) > 0 then $matching else
                  [$display.modes[] | select(
                    .width == $display.modes[$display.current_mode].width
                    and .height == $display.modes[$display.current_mode].height)]
                end)
              | min_by((.refresh_rate / 1000 - $fps) | fabs)
              | ["\(.width)x\(.height)@\(.refresh_rate / 1000)",
                 .width, .height, .refresh_rate] | @tsv
            ')
          IFS=$'\t' read -r target_mode width height refresh <<< "$target"
          echo "Client requested ''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}. Using $output $target_mode."
          niri msg output "$output" mode "$target_mode"
          niri msg output "$output" scale 1
          # Wait for the modeset before Sunshine initializes capture.
          for ((attempt = 0; attempt < 40; attempt++)); do
            if niri msg --json outputs | jq -e --arg output "$output" \
              --argjson width "$width" --argjson height "$height" --argjson refresh "$refresh" '
              .[$output] | .modes[.current_mode] as $mode
              | $mode.width == $width and $mode.height == $height
                and $mode.refresh_rate == $refresh and .logical.scale == 1
            ' > /dev/null; then
              exit 0
            fi
            sleep 0.05
          done
          echo "Niri did not apply the streaming display mode." >&2
          restore
          exit 1
          ;;
        restore)
          restore
          ;;
        *)
          echo "Expected start or restore." >&2
          exit 1
          ;;
      esac
    '';
  };
in {
  flake = {
    mkSunshineDisplay = mkSunshineDisplay;
    nixosModules = {
      sunshine = {
        config,
        utils,
        ...
      }: {
        boot.kernelModules = ["uhid"];
        users.users.grey.extraGroups = ["uinput"];
        services.udev.extraRules = ''
          SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="seat", TAG+="uaccess", OPTIONS+="static_node=uhid"
        '';
        services.sunshine = {
          enable = true;
          openFirewall = true;
          package = lib.mkDefault sunshine;
        };
        # Preserve configuration edited through Sunshine's web UI.
        systemd.user.services.sunshine.serviceConfig.ExecStart = lib.mkForce (utils.escapeSystemdExecArgs [
          (lib.getExe config.services.sunshine.package)
          "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
        ]);
      };

      sunshine-cuda = {
        config,
        pkgs,
        utils,
        ...
      }: let
        cudaSunshine =
          ((import inputs.sunshine-nixpkgs {
            system = pkgs.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).sunshine.override {cudaSupport = true;}).overrideAttrs (sunshineOverride {
            cudaSupport = true;
          });
        display = mkSunshineDisplay pkgs;
        prepCommands = builtins.toJSON [
          {
            do = "${lib.getExe display} start";
            undo = "${lib.getExe display} restore";
          }
        ];
      in {
        imports = [inputs.self.nixosModules.sunshine];
        services.sunshine.package = cudaSunshine;
        environment.systemPackages = [display];
        systemd.user.services.sunshine = {
          environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
          serviceConfig = {
            ExecStart = lib.mkOverride 40 (utils.escapeSystemdExecArgs [
              (lib.getExe config.services.sunshine.package)
              "csrf_allowed_origins=https://${config.networking.hostName}.tail1785c.ts.net:47990"
              "global_prep_cmd=${prepCommands}"
            ]);
            ExecStopPost = "-${lib.getExe display} restore";
          };
        };
      };
    };
  };
}
