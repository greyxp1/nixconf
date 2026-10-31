{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agent-desktop;
  swayConfig = pkgs.writeText "agent-desktop-sway.conf" ''
    xwayland disable
    output HEADLESS-1 mode ${toString cfg.width}x${toString cfg.height}
    seat seat0 fallback true
    default_border none
    font pango:monospace 10
  '';
  niriConfig = pkgs.writeText "agent-desktop-niri.kdl" ''
    output "winit" { mode "${toString cfg.width}x${toString cfg.height}"; }
    layout { gaps 8; default-column-width { proportion 1.0; }; }
    prefer-no-csd
    hotkey-overlay { skip-at-startup; }
    animations { off; }
    xwayland-satellite { off; }
  '';
  session = pkgs.writeShellApplication {
    name = "agent-desktop-session";
    runtimeInputs = [pkgs.coreutils pkgs.sway-unwrapped cfg.niriPackage pkgs.dbus pkgs.glib];
    text = ''
      session_dir=$1
      shift
      cleanup() {
        if [ -n "''${niri_pid:-}" ]; then
          kill "$niri_pid" 2>/dev/null || true
          wait "$niri_pid" 2>/dev/null || true
        fi
        kill "$compositor_pid" 2>/dev/null || true
        wait "$compositor_pid" 2>/dev/null || true
      }
      sway --unsupported-gpu --config ${swayConfig} >"$session_dir/compositor.log" 2>&1 &
      compositor_pid=$!
      trap cleanup EXIT
      for ((attempt = 0; attempt < 150; attempt++)); do
        kill -0 "$compositor_pid" 2>/dev/null || {
          cat "$session_dir/compositor.log" >&2
          exit 1
        }
        for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
          if [ -S "$socket" ]; then
            export WAYLAND_DISPLAY="''${socket##*/}"
            break 2
          fi
        done
        sleep 0.1
      done
      : "''${WAYLAND_DISPLAY:?Private Wayland session did not start}"
      outer_display=$WAYLAND_DISPLAY
      export LIBGL_ALWAYS_SOFTWARE=1
      export __EGL_VENDOR_LIBRARY_FILENAMES="''${__EGL_VENDOR_LIBRARY_FILENAMES:-${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json}"
      niri --config ${niriConfig} >"$session_dir/niri.log" 2>&1 &
      niri_pid=$!
      for ((attempt = 0; attempt < 200; attempt++)); do
        kill -0 "$niri_pid" 2>/dev/null || {
          cat "$session_dir/niri.log" >&2
          exit 1
        }
        for socket in "$XDG_RUNTIME_DIR"/niri.*.sock; do
          if [ -S "$socket" ]; then
            export NIRI_SOCKET="$socket"
          fi
        done
        for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
          if [ -S "$socket" ] && [ "''${socket##*/}" != "$outer_display" ]; then
            export WAYLAND_DISPLAY="''${socket##*/}"
          fi
        done
        if [ -n "''${NIRI_SOCKET:-}" ] && [ "$WAYLAND_DISPLAY" != "$outer_display" ]; then
          break
        fi
        sleep 0.1
      done
      : "''${NIRI_SOCKET:?Private Niri IPC socket is missing}"
      [ "$WAYLAND_DISPLAY" != "$outer_display" ] || {
        echo "Private Niri display did not start" >&2
        exit 1
      }
      export XDG_CURRENT_DESKTOP=niri
      # D-Bus was started before the compositor assigned its display socket.
      dbus-update-activation-environment WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP
      ${pkgs.at-spi2-core}/libexec/at-spi-bus-launcher --launch-immediately >"$session_dir/accessibility.log" 2>&1 &
      gdbus call --session --dest org.a11y.Bus --object-path /org/a11y/bus \
        --method org.freedesktop.DBus.Properties.Set org.a11y.Status IsEnabled '<true>' >/dev/null
      # D-Bus activation helpers must not write into the MCP transport.
      "$@" >&3 3>&-
    '';
  };
  launcher = pkgs.writeShellApplication {
    name = "agent-desktop";
    runtimeInputs = [pkgs.bubblewrap pkgs.coreutils pkgs.dbus pkgs.systemd pkgs.glib cfg.niriPackage];
    text = ''
      export CODEX_COMPUTER_USE_NIRI_AGENT=1
      export CODEX_COMPUTER_USE_NIRI_AGENT_REQUIRED=1
      export NIRI_AGENT_LAUNCH=1
      if [ "''${1:-}" = --desktop ]; then
        shift
        while IFS='=' read -r name value; do
          case "$name" in
            NIRI_SOCKET|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS)
              if [ -z "''${!name:-}" ]; then
                export "$name=$value"
              fi
              ;;
          esac
        done < <(systemctl --user show-environment)
        if [ "$#" = 0 ]; then
          set -- mcp
        fi
        exec ${cfg.package}/bin/codex-computer-use-linux "$@"
      fi
      session_dir=$(mktemp -d "''${XDG_RUNTIME_DIR:?}/agent-desktop.XXXXXXXX")
      trap 'rm -rf "$session_dir"' EXIT
      mkdir -p "$session_dir"/{home,runtime,config,cache,data,state}
      chmod 700 "$session_dir/runtime"
      workspace=$(pwd -P)
      workspace_args=()
      case "$workspace" in
        /|"$HOME"|/run|/run/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*|/tmp)
          workspace_args=(--chdir "$HOME") ;;
        *) workspace_args=(--bind "$workspace" "$workspace" --chdir "$workspace") ;;
      esac
      if [ "$#" = 0 ]; then
        set -- ${cfg.package}/bin/codex-computer-use-linux mcp
      fi
      bwrap --ro-bind / / --dev /dev --tmpfs /run \
        --ro-bind-try /run/current-system /run/current-system \
        --tmpfs /tmp --bind "$session_dir" "$session_dir" \
        --bind "$session_dir/home" "$HOME" "''${workspace_args[@]}" \
        --unshare-pid --proc /proc --unshare-ipc --die-with-parent --new-session \
        --unsetenv DISPLAY --unsetenv XAUTHORITY --unsetenv WAYLAND_DISPLAY --unsetenv WAYLAND_SOCKET \
        --unsetenv DBUS_SESSION_BUS_ADDRESS --unsetenv DBUS_STARTER_ADDRESS \
        --unsetenv DBUS_STARTER_BUS_TYPE --unsetenv DBUS_SYSTEM_BUS_ADDRESS \
        --unsetenv AT_SPI_BUS_ADDRESS --unsetenv NIRI_SOCKET --unsetenv HYPRLAND_INSTANCE_SIGNATURE \
        --unsetenv YDOTOOL_SOCKET --unsetenv SWAYSOCK \
        --setenv XDG_RUNTIME_DIR "$session_dir/runtime" \
        --setenv XDG_CONFIG_HOME "$session_dir/config" \
        --setenv XDG_CACHE_HOME "$session_dir/cache" \
        --setenv XDG_DATA_HOME "$session_dir/data" \
        --setenv XDG_STATE_HOME "$session_dir/state" \
        --unsetenv XDG_SESSION_ID --setenv XDG_SESSION_DESKTOP sway \
        --setenv TMPDIR /tmp --setenv XDG_SESSION_TYPE wayland \
        --setenv XDG_CURRENT_DESKTOP sway --setenv GDK_BACKEND wayland \
        --setenv QT_QPA_PLATFORM wayland --setenv ELECTRON_OZONE_PLATFORM_HINT wayland \
        --setenv WLR_BACKENDS headless --setenv WLR_RENDERER pixman \
        --setenv WLR_LIBINPUT_NO_DEVICES 1 --setenv WLR_HEADLESS_OUTPUTS 1 \
        --setenv NO_AT_BRIDGE 0 --setenv ACCESSIBILITY_ENABLED 1 \
        --setenv ATSPI_DBUS_IMPLEMENTATION dbus-daemon \
        --setenv DO_NOT_TRACK 1 \
        -- dbus-run-session -- ${lib.getExe session} "$session_dir" "$@" 3>&1 1>&2
    '';
  };
in {
  options.programs.agent-desktop = {
    enable = lib.mkEnableOption "isolated Wayland desktops for computer-use agents";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Niri-aware computer-use MCP backend.";
    };
    niriPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.niri;
      defaultText = lib.literalExpression "pkgs.niri";
      description = "Niri package with per-client agent input support.";
    };
    width = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1280;
      description = "Virtual output width in pixels.";
    };
    height = lib.mkOption {
      type = lib.types.ints.positive;
      default = 800;
      description = "Virtual output height in pixels.";
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Isolated desktop launcher.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.agent-desktop.finalPackage = launcher;
    environment.systemPackages = [launcher];
  };
}
